import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/ledger_id.dart';
import '../services/ledger_repository.dart';
import '../services/ledger_validation.dart';
import 'live_clock_viewmodel.dart';

export 'ledger_scope_viewmodel.dart';
export 'live_clock_viewmodel.dart' show clockProvider, nowProvider;

final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => throw UnimplementedError('Override at bootstrap'),
);
final ledgerProvider = AsyncNotifierProvider<LedgerViewModel, LedgerData>(
  LedgerViewModel.new,
  retry: (count, error) =>
      null, // Local failures stay visible until explicit Retry.
);

class LedgerViewModel extends AsyncNotifier<LedgerData> {
  bool get isCloud => false;
  int? accountRevision(String id) => null;
  int? usageRevision(String id) => null;
  int? quotaRevision(String accountId, String key) => null;
  int? get settingsRevision => null;
  bool _writing = false;
  int _loadEpoch = 0;
  Future<void>? _pendingWrite;
  final _ids = LedgerIdGenerator();
  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  Future<LedgerData> build() async {
    _loadEpoch++;
    final repository = ref.watch(ledgerRepositoryProvider);
    if (_pendingWrite != null) await _pendingWrite;
    final stored = await repository.load();
    if (stored != null) {
      LedgerValidation.snapshot(stored);
      return stored;
    }
    return LedgerData(accounts: [], sessions: []);
  }

  Future<void> _persist(
    LedgerData next,
    Future<void> Function(LedgerData) write,
  ) async {
    if (_writing) {
      throw StateError('Đang lưu thay đổi trước. Vui lòng thử lại.');
    }
    LedgerValidation.snapshot(next);
    _writing = true;
    final done = Completer<void>();
    _pendingWrite = done.future;
    try {
      await write(next);
    } finally {
      _writing = false;
      _pendingWrite = null;
      done.complete();
    }
  }

  LedgerData get _data {
    if (state.isLoading || !state.hasValue) {
      throw StateError('Dữ liệu chưa sẵn sàng. Hãy thử tải lại.');
    }
    return state.requireValue;
  }

  Future<void> _commit(LedgerData next) async {
    final repository = _repository;
    final epoch = _loadEpoch;
    _data;
    await _persist(next, repository.save);
    if (ref.mounted && epoch == _loadEpoch) state = AsyncData(next);
  }

  String newId() {
    String id;
    do {
      id = _ids.next();
    } while (state.asData?.value.account(id) != null ||
        (state.asData?.value.sessions.any((s) => s.id == id) ?? false));
    return id;
  }

  Future<void> saveAccount(AIAccount account, {int? expectedRevision}) async {
    LedgerValidation.account(account);
    final data = _data;
    final previous = data.account(account.id);
    if (previous != null &&
        !previous.createdAt.isAtSameMomentAs(account.createdAt)) {
      throw ArgumentError('Không đổi thời điểm tạo tài khoản.');
    }
    if (previous == null &&
        account.createdAt.isAfter(ref.read(clockProvider)())) {
      throw ArgumentError('Thời điểm tạo không được ở tương lai.');
    }
    if (previous != null &&
        (previous.isDemo != account.isDemo ||
            previous.dataSource != account.dataSource)) {
      throw ArgumentError('Không đổi nguồn dữ liệu của tài khoản.');
    }
    for (final quota in account.quotaWindows) {
      final old = previous?.quotaWindows
          .where((q) => q.windowKey == quota.windowKey)
          .firstOrNull;
      final same =
          old != null && old.toJson().toString() == quota.toJson().toString();
      if (!same) LedgerValidation.quota(quota, now: ref.read(clockProvider)());
    }
    await _commit(
      data.copyWith(
        accounts: [...data.accounts.where((a) => a.id != account.id), account],
      ),
    );
  }

  Future<void> archiveAccount(String id, bool archive) async {
    final account = _data.account(id);
    if (account == null) throw StateError('Không tìm thấy tài khoản.');
    await saveAccount(account.copyWith(archived: archive));
  }

  Future<void> deleteAccount(String id) async {
    final data = _data;
    if (data.account(id) == null) throw StateError('Không tìm thấy tài khoản.');
    if (data.sessions.any((s) => s.accountId == id)) {
      throw StateError(
        'Tài khoản còn phiên sử dụng. Hãy lưu trữ hoặc xóa các phiên trước.',
      );
    }
    await _commit(
      data.copyWith(accounts: data.accounts.where((a) => a.id != id).toList()),
    );
  }

  Future<void> saveUsage(UsageSession session, {int? expectedRevision}) async {
    LedgerValidation.usage(session, now: ref.read(clockProvider)());
    final data = _data;
    final account = data.account(session.accountId);
    final previous = data.sessions.where((s) => s.id == session.id).firstOrNull;
    if (previous != null && previous.accountId != session.accountId) {
      throw StateError('Không đổi tài khoản của phiên đã lưu.');
    }
    if (previous != null &&
        (previous.dataSource != session.dataSource ||
            previous.isDemo != session.isDemo)) {
      throw ArgumentError('Không đổi nguồn dữ liệu của phiên lịch sử.');
    }
    if (account == null || (account.archived && previous == null)) {
      throw StateError('Chọn tài khoản đang hoạt động.');
    }
    await _commit(
      data.copyWith(
        sessions: [...data.sessions.where((s) => s.id != session.id), session],
      ),
    );
  }

  Future<void> deleteUsage(String id) async {
    final data = _data;
    if (!data.sessions.any((s) => s.id == id)) {
      throw StateError('Không tìm thấy phiên sử dụng.');
    }
    await _commit(
      data.copyWith(sessions: data.sessions.where((s) => s.id != id).toList()),
    );
  }

  Future<void> updateQuota(
    String accountId,
    QuotaSnapshot quota, {
    bool requireExisting = false,
    int? expectedRevision,
  }) async {
    LedgerValidation.quota(quota, now: ref.read(clockProvider)());
    final account = _data.account(accountId);
    if (account == null) throw StateError('Không tìm thấy tài khoản.');
    if (requireExisting &&
        !account.quotaWindows.any((q) => q.windowKey == quota.windowKey)) {
      throw StateError(
        'Cửa sổ hạn mức đã bị xóa. Quay lại chi tiết để thêm mới.',
      );
    }
    final matching =
        account.quotaWindows
            .where((q) => q.windowKey == quota.windowKey)
            .firstOrNull ??
        account.quotaWindows
            .where(
              (q) =>
                  q.window.trim().toLowerCase() ==
                  quota.window.trim().toLowerCase(),
            )
            .firstOrNull;
    await saveAccount(
      account.copyWith(
        quota: matching == null
            ? quota
            : quota.copyWith(windowKey: matching.windowKey),
      ),
    );
  }

  Future<void> deleteQuota(String accountId, String windowKey) async {
    final account = _data.account(accountId);
    if (account == null ||
        !account.quotaWindows.any((q) => q.windowKey == windowKey)) {
      throw StateError('Không tìm thấy cửa sổ hạn mức.');
    }
    await saveAccount(
      account.copyWith(
        quotaWindows: account.quotaWindows
            .where((q) => q.windowKey != windowKey)
            .toList(),
      ),
    );
  }

  Future<void> setReportingTimezone(
    String zone, {
    int? expectedRevision,
  }) async => _commit(_data.copyWith(reportingTimezone: zone.trim()));
}
