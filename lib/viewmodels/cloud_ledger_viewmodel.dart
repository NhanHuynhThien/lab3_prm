import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cloud_ledger.dart';
import '../models/cloud_sync_status.dart';
import '../models/ledger.dart';
import '../services/analytics_service.dart';
import '../services/cloud_ledger_repository.dart';
import '../services/ledger_validation.dart';
import 'auto_ledger_link.dart';
import 'cloud_ledger_mutations.dart';
import 'ledger_viewmodel.dart';
import 'product_features_viewmodel.dart';

export '../models/cloud_sync_status.dart';

final cloudSyncProvider = Provider<CloudSyncStatus>((ref) {
  final value = ref.watch(ledgerProvider);
  if (value.hasError) return CloudSyncStatus(error: value.error);
  final vm = ref.watch(ledgerProvider.notifier);
  return vm is CloudLedgerViewModel ? vm.sync : const CloudSyncStatus();
});

class _PendingCommand {
  _PendingCommand(this.signature, this.id, this.execute, this.event);
  final String signature, id;
  final Future<void> Function(String) execute;
  final ProductEvent? event;
}

class CloudLedgerViewModel extends LedgerViewModel
    with CloudLedgerMutations, AutoLedgerLink {
  @override
  bool get isCloud => true;
  CloudSyncStatus sync = const CloudSyncStatus();
  late CloudLedgerRepository _repo;
  @override
  CloudLedgerRepository get repo => _repo;
  final _subscriptions = <StreamSubscription<Object?>>[];
  CloudSnapshot<AIAccount>? _accounts;
  CloudSnapshot<UsageSession>? _usage;
  CloudSnapshot<AccountQuota>? _quotas;
  CloudSnapshot<CloudSettings>? _settings;
  LedgerData? _last;
  @override
  LedgerData? get lastData => _last;
  var _epoch = 0;
  var _busy = false;
  var _bootActive = true;
  Object? _streamFailure;
  Completer<LedgerData>? _waiting;
  Future<LedgerData>? _connecting;
  final _commands = <String, _PendingCommand>{};
  void Function()? _republish;

  @override
  Future<LedgerData> build() {
    _repo = ref.watch(cloudRepositoryProvider);
    watchAuto(() => _republish?.call());
    ref.onDispose(() {
      _epoch++;
      final waiting = _waiting;
      if (waiting != null && !waiting.isCompleted) {
        waiting.completeError(CloudLedgerFailure.workspaceClosed);
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
      throw CloudLedgerFailure.workspaceClosed;
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
    var serverSeen = false;
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

      final usageCounts = <String, int>{};
      for (final r in u.records) {
        final id = r.value.accountId;
        usageCounts[id] = (usageCounts[id] ?? 0) + 1;
      }
      final quotasByAccount = <String, List<QuotaSnapshot>>{};
      final quotaCounts = <String, int>{};
      for (final r in q.records) {
        final id = r.value.accountId;
        quotaCounts[id] = (quotaCounts[id] ?? 0) + 1;
        (quotasByAccount[id] ??= []).add(r.value.snapshot);
      }

      final coherent =
          u.records.every((r) => ids.contains(r.value.accountId)) &&
          q.records.every((r) => ids.contains(r.value.accountId)) &&
          a.records.every(
            (r) =>
                r.usageCount == (usageCounts[r.id] ?? 0) &&
                r.quotaCount == (quotaCounts[r.id] ?? 0),
          );
      final cached = a.fromCache || u.fromCache || q.fromCache || s.fromCache;
      serverSeen = serverSeen || !cached;
      sync = CloudSyncStatus(
        loading: !serverSeen,
        coherent: coherent,
        fromCache: cached,
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
      // Persistence is off, so an unconfirmed offline snapshot is just empty.
      if (!serverSeen) return;
      try {
        final manual = LedgerData(
          accounts: a.records
              .map(
                (r) => r.value.copyWith(
                  quotaWindows: quotasByAccount[r.id] ?? const [],
                ),
              )
              .toList(),
          sessions: u.records.map((r) => r.value).toList(),
          reportingTimezone:
              s.records.firstOrNull?.value.reportingTimezone ??
              'Asia/Ho_Chi_Minh',
        );
        LedgerValidation.snapshot(manual);
        final data = withAuto(manual);
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

    _republish = publish;
    try {
      listen(_repo.watchAccounts(), (v) => _accounts = v);
      listen(_repo.watchAllUsage(), (v) => _usage = v);
      listen(_repo.watchAllQuotas(), (v) => _quotas = v);
      listen(_repo.watchSettings(), (v) => _settings = v);
      return await ready.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw CloudLedgerFailure.serverUnreachable,
      );
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

  @override
  bool hasUnconfirmed(String key) => _commands.containsKey(key);

  @override
  Future<void> run(
    String key,
    Object payload,
    Future<void> Function(String) execute, {
    ProductEvent? event,
  }) async {
    if (_busy) throw StateError('Đang lưu thay đổi trước.');
    _ready();
    final signature = jsonEncode(payload);
    // Same content retries the same operation ID; edited content is a new one.
    var command = _commands[key];
    if (command?.signature != signature) {
      command = _PendingCommand(signature, newId(), execute, event);
    }
    _commands[key] = command!;
    _busy = true;
    try {
      await command.execute(command.id);
      if (!ref.mounted) throw StateError('Không gian dữ liệu đã đóng.');
      _commands.remove(key);
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .record(command.event, operationId: command.id),
      );
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
}
