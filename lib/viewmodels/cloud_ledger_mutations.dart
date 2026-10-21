import '../models/cloud_ledger.dart';
import '../models/ledger.dart';
import '../services/analytics_service.dart';
import '../services/cloud_ledger_repository.dart';
import '../services/ledger_validation.dart';
import 'ledger_viewmodel.dart';

mixin CloudLedgerMutations on LedgerViewModel {
  CloudLedgerRepository get repo;
  LedgerData? get lastData;
  Future<void> run(
    String key,
    Object payload,
    Future<void> Function(String) execute, {
    ProductEvent? event,
  });

  @override
  Future<void> saveAccount(AIAccount account, {int? expectedRevision}) {
    LedgerValidation.account(account);
    final value = account.copyWith(quotaWindows: []);
    final exists =
        expectedRevision != 0 && lastData?.account(account.id) != null;
    final revision = expectedRevision ?? accountRevision(account.id);
    return run('account/${account.id}', value.toJson(), (op) async {
      if (exists) {
        await repo.updateAccount(
          value,
          expectedRevision: revision!,
          operationId: op,
        );
      } else if (expectedRevision != null && expectedRevision != 0) {
        throw StateError('Tài khoản đã bị xóa.');
      } else {
        await repo.createAccount(value, operationId: op);
      }
    }, event: ProductEvent.mutation('account', exists ? 'update' : 'create'));
  }

  @override
  Future<void> archiveAccount(String id, bool archive) => saveAccount(
    lastData!.account(id)!.copyWith(archived: archive),
    expectedRevision: accountRevision(id),
  );

  @override
  Future<void> deleteAccount(String id) {
    if (lastData?.account(id)?.quotaWindows.isNotEmpty == true) {
      throw StateError(
        'Tài khoản còn hạn mức. Xóa từng cửa sổ hoặc lưu trữ tài khoản.',
      );
    }
    final revision = accountRevision(id);
    return run(
      'deleteAccount/$id',
      id,
      (op) =>
          repo.deleteAccount(id, expectedRevision: revision!, operationId: op),
      event: ProductEvent.mutation('account', 'delete'),
    );
  }

  @override
  Future<void> saveUsage(UsageSession session, {int? expectedRevision}) {
    LedgerValidation.usage(session, now: ref.read(clockProvider)());
    final revision = expectedRevision == 0
        ? null
        : expectedRevision ?? usageRevision(session.id);
    return run(
      'usage/${session.id}',
      session.toJson(),
      (op) async {
        if (revision != null) {
          await repo.updateUsage(
            session,
            expectedRevision: revision,
            operationId: op,
          );
        } else {
          await repo.createUsage(session, operationId: op);
        }
      },
      event: ProductEvent.mutation(
        'usage',
        revision == null ? 'create' : 'update',
      ),
    );
  }

  @override
  Future<void> deleteUsage(String id) {
    final revision = usageRevision(id);
    return run(
      'deleteUsage/$id',
      id,
      (op) =>
          repo.deleteUsage(id, expectedRevision: revision!, operationId: op),
      event: ProductEvent.mutation('usage', 'delete'),
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
    return run(
      'quota/$accountId/${quota.windowKey}',
      quota.toJson(),
      (op) async {
        if (revision != null) {
          await repo.updateQuota(
            value,
            expectedRevision: revision,
            operationId: op,
          );
        } else if (requireExisting) {
          throw StateError('Cửa sổ đã bị xóa.');
        } else {
          await repo.createQuota(value, operationId: op);
        }
      },
      event: ProductEvent.mutation(
        'quota',
        revision == null ? 'create' : 'update',
      ),
    );
  }

  @override
  Future<void> deleteQuota(String accountId, String windowKey) {
    final revision = quotaRevision(accountId, windowKey);
    return run(
      'deleteQuota/$accountId/$windowKey',
      windowKey,
      (op) => repo.deleteQuota(
        accountId,
        windowKey,
        expectedRevision: revision!,
        operationId: op,
      ),
      event: ProductEvent.mutation('quota', 'delete'),
    );
  }

  @override
  Future<void> setReportingTimezone(String zone, {int? expectedRevision}) {
    final revision = expectedRevision == 0
        ? null
        : expectedRevision ?? settingsRevision;
    return run('settings', zone, (op) async {
      await repo.setReportingTimezone(
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
