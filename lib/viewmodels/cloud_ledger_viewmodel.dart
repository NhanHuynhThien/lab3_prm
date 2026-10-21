import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cloud_ledger.dart';
import '../models/ledger.dart';
import '../services/cloud_ledger_repository.dart';
import '../services/firestore_ledger_repository.dart';
import '../services/ledger_validation.dart';
import 'ledger_viewmodel.dart';

final cloudRepositoryFactoryProvider =
    Provider<CloudLedgerRepository Function()>(
      (ref) => FirestoreLedgerRepository.forCurrentUser,
    );
final cloudOwnerProvider = Provider<String?>((ref) => null);
final cloudRepositoryProvider = Provider.autoDispose<CloudLedgerRepository>((
  ref,
) {
  final repo = ref.read(cloudRepositoryFactoryProvider)();
  if (repo.ownerId != ref.read(cloudOwnerProvider)) {
    unawaited(repo.close());
    throw const CloudLedgerFailure(
      CloudLedgerProblem.unauthenticated,
      'Phiên đã thay đổi.',
    );
  }
  ref.onDispose(() => unawaited(repo.close()));
  return repo;
});

class CloudSyncStatus {
  const CloudSyncStatus({
    this.loading = true,
    this.fromCache = false,
    this.pending = false,
    this.error,
    this.coherent = false,
  });
  final bool loading, fromCache, pending, coherent;
  final Object? error;
  bool get confirmed =>
      !loading && !fromCache && !pending && coherent && error == null;
  String get label => error != null
      ? 'Lỗi kết nối'
      : loading || !coherent
      ? 'Đang đồng bộ'
      : pending
      ? 'Chờ xác nhận'
      : fromCache
      ? 'Bản lưu cache'
      : 'Đã kết nối';
}

final cloudSyncProvider = Provider<CloudSyncStatus>((ref) {
  final value = ref.watch(ledgerProvider);
  if (value.hasError) return CloudSyncStatus(error: value.error);
  final vm = ref.watch(ledgerProvider.notifier);
  return vm is CloudLedgerViewModel ? vm.sync : const CloudSyncStatus();
});

class _PendingCommand {
  _PendingCommand(this.signature, this.id, this.execute);
  final String signature, id;
  final Future<void> Function(String) execute;
}

/// Shared screen API; cloud overrides every local mutation and never save(snapshot).
class CloudLedgerViewModel extends LedgerViewModel {
  @override
  bool get isCloud => true;
  CloudSyncStatus sync = const CloudSyncStatus();
  late CloudLedgerRepository _repo;
  final _subscriptions = <StreamSubscription<Object?>>[];
  CloudSnapshot<AIAccount>? _accounts;
  CloudSnapshot<UsageSession>? _usage;
  CloudSnapshot<AccountQuota>? _quotas;
  CloudSnapshot<CloudSettings>? _settings;
  LedgerData? _last;
  var _epoch = 0;
  var _busy = false;
  var _bootActive = true;
  Object? _streamFailure;
  Completer<LedgerData>? _waiting;
  Future<LedgerData>? _connecting;
  final _commands = <String, _PendingCommand>{};

  @override
  Future<LedgerData> build() {
    _repo = ref.watch(cloudRepositoryProvider);
    ref.onDispose(() {
      _epoch++;
      final waiting = _waiting;
      if (waiting != null && !waiting.isCompleted) {
        waiting.completeError(
          const CloudLedgerFailure(
            CloudLedgerProblem.closed,
            'Không gian dữ liệu đã đóng.',
          ),
        );
      }
      for (final sub in _subscriptions) {
        unawaited(sub.cancel());
      }
      _subscriptions.clear();
      _commands.clear();
      _last = null;
      _accounts = null;
      _usage = null;
      _quotas = null;
      _settings = null;
    });
    final connecting = _connect();
    _connecting = connecting;
    return connecting.whenComplete(() {
      _bootActive = false;
      if (identical(_connecting, connecting)) _connecting = null;
    });
  }

  Future<LedgerData> _connect() async {
    final epoch = ++_epoch;
    await Future.wait(_subscriptions.map((sub) => sub.cancel()));
    if (!ref.mounted || epoch != _epoch) {
      throw const CloudLedgerFailure(
        CloudLedgerProblem.closed,
        'Không gian dữ liệu đã đóng.',
      );
    }
    _subscriptions.clear();
    _accounts = null;
    _usage = null;
    _quotas = null;
    _settings = null;
    _streamFailure = null;
    sync = const CloudSyncStatus();
    if (_last != null && ref.mounted) state = AsyncData(_last!.copyWith());
    final ready = Completer<LedgerData>();
    _waiting = ready;
    void fail(Object error) {
      if (!ref.mounted || epoch != _epoch) return;
      sync = CloudSyncStatus(error: error);
      _streamFailure = error;
      if (error is CloudLedgerFailure &&
          [
            CloudLedgerProblem.unauthenticated,
            CloudLedgerProblem.closed,
          ].contains(error.problem)) {
        _last = null;
        _accounts = null;
        _usage = null;
        _quotas = null;
        _settings = null;
        if (!_bootActive) state = AsyncError(error, StackTrace.current);
      } else if (_last != null) {
        state = AsyncData(_last!.copyWith());
      }
      if (!ready.isCompleted) ready.completeError(error);
    }

    void publish() {
      if (!ref.mounted || epoch != _epoch) return;
      if (_streamFailure != null) return;
      final a = _accounts, u = _usage, q = _quotas, s = _settings;
      if (a == null || u == null || q == null || s == null) return;
      final ids = a.records.map((r) => r.id).toSet();
      final coherent =
          u.records.every((r) => ids.contains(r.value.accountId)) &&
          q.records.every((r) => ids.contains(r.value.accountId)) &&
          a.records.every(
            (r) =>
                r.usageCount ==
                    u.records.where((v) => v.value.accountId == r.id).length &&
                r.quotaCount ==
                    q.records.where((v) => v.value.accountId == r.id).length,
          );
      sync = CloudSyncStatus(
        loading: false,
        coherent: coherent,
        fromCache: a.fromCache || u.fromCache || q.fromCache || s.fromCache,
        pending:
            a.hasPendingWrites ||
            u.hasPendingWrites ||
            q.hasPendingWrites ||
            s.hasPendingWrites,
      );
      if (!coherent) {
        if (_last != null) state = AsyncData(_last!.copyWith());
        return;
      }
      try {
        final data = LedgerData(
          accounts: a.records
              .map(
                (r) => r.value.copyWith(
                  quotaWindows: q.records
                      .where((v) => v.value.accountId == r.id)
                      .map((v) => v.value.snapshot)
                      .toList(),
                ),
              )
              .toList(),
          sessions: u.records.map((r) => r.value).toList(),
          reportingTimezone:
              s.records.firstOrNull?.value.reportingTimezone ??
              'Asia/Ho_Chi_Minh',
        );
        LedgerValidation.snapshot(data);
        _last = data;
        if (!ready.isCompleted) ready.complete(data);
        if (!_bootActive) state = AsyncData(data);
      } catch (error) {
        fail(error);
      }
    }

    void listen<T>(
      Stream<CloudSnapshot<T>> stream,
      void Function(CloudSnapshot<T>) save,
    ) {
      _subscriptions.add(
        stream.listen((snapshot) {
          if (ref.mounted && epoch == _epoch) {
            save(snapshot);
            publish();
          }
        }, onError: fail),
      );
    }

    try {
      listen(_repo.watchAccounts(), (v) => _accounts = v);
      listen(_repo.watchAllUsage(), (v) => _usage = v);
      listen(_repo.watchAllQuotas(), (v) => _quotas = v);
      listen(_repo.watchSettings(), (v) => _settings = v);
      return await ready.future.timeout(const Duration(seconds: 20));
    } catch (error) {
      fail(error);
      rethrow;
    }
  }

  Future<void> retry() async {
    final connecting = _connecting ??= _connect();
    try {
      await connecting;
    } finally {
      if (identical(_connecting, connecting)) _connecting = null;
    }
  }

  void _ready() {
    if (!ref.mounted || _last == null || !sync.confirmed) {
      throw const CloudLedgerFailure(
        CloudLedgerProblem.unavailable,
        'Cần dữ liệu đã xác nhận từ máy chủ trước khi lưu. Giữ bản nháp và thử kết nối lại.',
      );
    }
  }

  @override
  int? accountRevision(String id) =>
      _accounts?.records.where((r) => r.id == id).firstOrNull?.revision;
  @override
  int? usageRevision(String id) =>
      _usage?.records.where((r) => r.id == id).firstOrNull?.revision;
  @override
  int? quotaRevision(String accountId, String key) => _quotas?.records
      .where(
        (r) =>
            r.value.accountId == accountId && r.value.snapshot.windowKey == key,
      )
      .firstOrNull
      ?.revision;
  @override
  int? get settingsRevision => _settings?.records.firstOrNull?.revision;

  Future<void> _run(
    String key,
    Object payload,
    Future<void> Function(String) execute,
  ) async {
    if (_busy) throw StateError('Đang lưu thay đổi trước.');
    _ready();
    final signature = jsonEncode(payload);
    var command = _commands[key];
    if (command != null && command.signature != signature) {
      throw StateError(
        'Thao tác trước chưa rõ kết quả. Thử lại với nội dung cũ trước khi sửa tiếp.',
      );
    }
    command ??= _PendingCommand(signature, newId(), execute);
    _commands[key] = command;
    _busy = true;
    try {
      await command.execute(command.id);
      if (!ref.mounted) throw StateError('Không gian dữ liệu đã đóng.');
      _commands.remove(key);
      // Stream is the sole state authority. Never publish a guessed next snapshot.
    } catch (error) {
      if (error is! CloudLedgerFailure ||
          error.problem != CloudLedgerProblem.unavailable) {
        _commands.remove(key);
      }
      rethrow;
    } finally {
      _busy = false;
    }
  }

  @override
  Future<void> saveAccount(AIAccount account, {int? expectedRevision}) {
    LedgerValidation.account(account);
    final value = account.copyWith(quotaWindows: []);
    final exists = expectedRevision != 0 && _last?.account(account.id) != null;
    final revision = expectedRevision ?? accountRevision(account.id);
    return _run('account/${account.id}', value.toJson(), (op) async {
      if (exists) {
        await _repo.updateAccount(
          value,
          expectedRevision: revision!,
          operationId: op,
        );
      } else if (expectedRevision != null && expectedRevision != 0) {
        throw StateError('Tài khoản đã bị xóa.');
      } else {
        await _repo.createAccount(value, operationId: op);
      }
    });
  }

  @override
  Future<void> archiveAccount(String id, bool archive) => saveAccount(
    _last!.account(id)!.copyWith(archived: archive),
    expectedRevision: accountRevision(id),
  );
  @override
  Future<void> deleteAccount(String id) {
    if (_last?.account(id)?.quotaWindows.isNotEmpty == true) {
      throw StateError(
        'Tài khoản còn hạn mức. Xóa từng cửa sổ hoặc lưu trữ tài khoản.',
      );
    }
    final revision = accountRevision(id);
    return _run(
      'deleteAccount/$id',
      id,
      (op) =>
          _repo.deleteAccount(id, expectedRevision: revision!, operationId: op),
    );
  }

  @override
  Future<void> saveUsage(UsageSession session, {int? expectedRevision}) {
    LedgerValidation.usage(session, now: ref.read(clockProvider)());
    final revision = expectedRevision == 0
        ? null
        : expectedRevision ?? usageRevision(session.id);
    return _run('usage/${session.id}', session.toJson(), (op) async {
      if (revision != null) {
        await _repo.updateUsage(
          session,
          expectedRevision: revision,
          operationId: op,
        );
      } else {
        await _repo.createUsage(session, operationId: op);
      }
    });
  }

  @override
  Future<void> deleteUsage(String id) {
    final revision = usageRevision(id);
    return _run(
      'deleteUsage/$id',
      id,
      (op) =>
          _repo.deleteUsage(id, expectedRevision: revision!, operationId: op),
    );
  }

  @override
  Future<void> updateQuota(
    String accountId,
    QuotaSnapshot quota, {
    bool requireExisting = false,
    int? expectedRevision,
  }) {
    final revision = expectedRevision == 0
        ? null
        : expectedRevision ?? quotaRevision(accountId, quota.windowKey);
    final value = AccountQuota(accountId: accountId, snapshot: quota);
    return _run('quota/$accountId/${quota.windowKey}', quota.toJson(), (
      op,
    ) async {
      if (revision != null) {
        await _repo.updateQuota(
          value,
          expectedRevision: revision,
          operationId: op,
        );
      } else if (requireExisting) {
        throw StateError('Cửa sổ đã bị xóa.');
      } else {
        await _repo.createQuota(value, operationId: op);
      }
    });
  }

  @override
  Future<void> deleteQuota(String accountId, String windowKey) {
    final revision = quotaRevision(accountId, windowKey);
    return _run(
      'deleteQuota/$accountId/$windowKey',
      windowKey,
      (op) => _repo.deleteQuota(
        accountId,
        windowKey,
        expectedRevision: revision!,
        operationId: op,
      ),
    );
  }

  @override
  Future<void> setReportingTimezone(String zone, {int? expectedRevision}) {
    final revision = expectedRevision == 0
        ? null
        : expectedRevision ?? settingsRevision;
    return _run('settings', zone, (op) async {
      await _repo.setReportingTimezone(
        zone.trim(),
        expectedRevision: revision,
        operationId: op,
      );
    });
  }

  @override
  Future<void> resetDemo() async =>
      throw StateError('Mở demo local riêng để khôi phục dữ liệu mẫu.');
  @override
  Future<void> clearDemo() async =>
      throw StateError('Không xóa demo trong không gian cloud.');
  @override
  Future<void> recoverDemo() async =>
      throw StateError('Cloud không dùng khôi phục snapshot local.');
}
