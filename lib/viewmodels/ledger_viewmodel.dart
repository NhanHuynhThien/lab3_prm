import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/demo_seed.dart';
import '../services/ledger_repository.dart';
import '../services/usage_calculator.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => throw UnimplementedError('Override at bootstrap'),
);
final ledgerProvider = AsyncNotifierProvider<LedgerViewModel, LedgerData>(
  LedgerViewModel.new,
);
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class LedgerViewModel extends AsyncNotifier<LedgerData> {
  bool _writing = false;
  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);
  @override
  Future<LedgerData> build() async {
    final stored = await _repository.load();
    if (stored != null) return stored;
    final seed = createDemoSeed(ref.read(clockProvider)());
    await _repository.save(seed);
    return seed;
  }

  Future<void> _commit(LedgerData next) async {
    if (_writing) {
      throw StateError('Đang lưu thay đổi trước. Vui lòng thử lại.');
    }
    _writing = true;
    try {
      await _repository.save(next);
      state = AsyncData(next);
    } finally {
      _writing = false;
    }
  }

  String newId() => ref.read(clockProvider)().microsecondsSinceEpoch.toString();
  Future<void> saveAccount(AIAccount account) async {
    if (account.alias.trim().isEmpty || account.alias.length > 80) {
      throw ArgumentError('Tên tài khoản cần 1–80 ký tự.');
    }
    if (account.budgetMicros != null && account.budgetMicros! < 0) {
      throw ArgumentError('Ngân sách không được âm.');
    }
    final data = state.requireValue;
    await _commit(
      data.copyWith(
        accounts: [...data.accounts.where((a) => a.id != account.id), account],
      ),
    );
  }

  Future<void> archiveAccount(String id, bool archive) async {
    final account = state.requireValue.account(id);
    if (account == null) throw StateError('Không tìm thấy tài khoản.');
    await saveAccount(account.copyWith(archived: archive));
  }

  Future<void> deleteAccount(String id) async {
    final data = state.requireValue;
    if (data.sessions.any((s) => s.accountId == id)) {
      throw StateError(
        'Tài khoản còn phiên sử dụng. Hãy lưu trữ hoặc xóa các phiên trước.',
      );
    }
    await _commit(
      data.copyWith(accounts: data.accounts.where((a) => a.id != id).toList()),
    );
  }

  Future<void> saveUsage(UsageSession session) async {
    final data = state.requireValue;
    final account = data.account(session.accountId);
    if (account == null || account.archived) {
      throw StateError('Chọn tài khoản đang hoạt động.');
    }
    if (session.title.trim().isEmpty || session.title.length > 120) {
      throw ArgumentError('Tên công việc cần 1–120 ký tự.');
    }
    for (final value in [
      session.inputTokens,
      session.outputTokens,
      session.costMicros,
    ]) {
      if (value != null && value < 0) {
        throw ArgumentError('Số liệu không được âm.');
      }
    }
    if ((session.inputTokens == null) != (session.outputTokens == null)) {
      throw ArgumentError('Nhập cả input và output, hoặc để trống cả hai.');
    }
    final previous = data.sessions.where((s) => s.id == session.id).firstOrNull;
    if (previous != null && previous.accountId != session.accountId) {
      throw StateError('Không đổi tài khoản của phiên đã lưu.');
    }
    await _commit(
      data.copyWith(
        sessions: [...data.sessions.where((s) => s.id != session.id), session],
      ),
    );
  }

  Future<void> deleteUsage(String id) => _commit(
    state.requireValue.copyWith(
      sessions: state.requireValue.sessions.where((s) => s.id != id).toList(),
    ),
  );
  Future<void> updateQuota(String accountId, QuotaSnapshot quota) async {
    final now = ref.read(clockProvider)();
    if (quota.usedPercent < 0 ||
        quota.usedPercent > 100 ||
        !quota.resetAt.isAfter(now)) {
      throw ArgumentError(
        'Quota cần 0–100% và thời điểm reset trong tương lai.',
      );
    }
    await saveAccount(
      state.requireValue.account(accountId)!.copyWith(quota: quota),
    );
  }

  Future<void> resetDemo() =>
      _commit(createDemoSeed(ref.read(clockProvider)()));
  Future<void> clearDemo() => _commit(LedgerData(accounts: [], sessions: []));
}

class DemoSessionViewModel extends Notifier<bool> {
  @override
  bool build() => Uri.base.queryParameters['demo'] == '1';
  void enter() => state = true;
  void leave() => state = false;
}

final demoSessionProvider = NotifierProvider<DemoSessionViewModel, bool>(
  DemoSessionViewModel.new,
);

class RangeViewModel extends Notifier<UsageRange> {
  @override
  UsageRange build() => UsageRange.month;
  void select(UsageRange range) => state = range;
}

final rangeProvider = NotifierProvider<RangeViewModel, UsageRange>(
  RangeViewModel.new,
);
final filteredSessionsProvider = Provider<List<UsageSession>>((ref) {
  final data = ref.watch(ledgerProvider).asData?.value;
  return UsageCalculator.filter(
    data?.sessions ?? [],
    ref.watch(clockProvider)(),
    range: ref.watch(rangeProvider),
  );
});
