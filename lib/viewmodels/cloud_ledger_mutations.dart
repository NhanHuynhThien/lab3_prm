import '../models/cloud_ledger.dart';
import '../models/ledger.dart';
import '../services/analytics_service.dart';
import '../services/cloud_ledger_repository.dart';
import '../services/ledger_validation.dart';
import 'ledger_viewmodel.dart';

mixin CloudLedgerMutations on LedgerViewModel {
  CloudLedgerRepository get repo;
  LedgerData? get lastData;

  /// True after a save whose outcome is unknown: it may have committed, so the
  /// next edit must build on the latest revision instead of the form's copy.
  bool hasUnconfirmed(String key);
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
    final key = 'account/${account.id}';
    final uncertain = hasUnconfirmed(key);
    final exists =
        (expectedRevision != 0 || uncertain) &&
        lastData?.account(account.id) != null;
    final revision = uncertain
        ? accountRevision(account.id)
        : expectedRevision ?? accountRevision(account.id);
    return run(key, value.toJson(), (op) async {
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
    final key = 'usage/${session.id}';
    final revision = hasUnconfirmed(key)
        ? usageRevision(session.id)
        : expectedRevision == 0
        ? null
        : expectedRevision ?? usageRevision(session.id);
    return run(
      key,
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
    final account = lastData?.account(accountId);
    if (account?.archived == true) {
      throw StateError(
        'Tài khoản đã lưu trữ. Hãy khôi phục trước khi cập nhật hạn mức.',
      );
    }
    final windows = account?.quotaWindows ?? const <QuotaSnapshot>[];
    final adding = expectedRevision == 0 && !requireExisting;
    final label = quota.window.trim().toLowerCase();
    final sameName = adding
        ? windows
              .where((q) => q.window.trim().toLowerCase() == label)
              .firstOrNull
        : null;
    // A renamed window keeps its key, so a new window can reuse only its name.
    final target = sameName != null
        ? quota.copyWith(windowKey: sameName.windowKey)
        : adding && windows.any((q) => q.windowKey == quota.windowKey)
        ? quota.copyWith(windowKey: '${quota.windowKey}#${newId()}')
        : quota;
    final key = 'quota/$accountId/${target.windowKey}';
    final revision = sameName != null || hasUnconfirmed(key)
        ? quotaRevision(accountId, target.windowKey)
        : expectedRevision == 0
        ? null
        : expectedRevision ?? quotaRevision(accountId, target.windowKey);
    final value = AccountQuota(accountId: accountId, snapshot: target);
    return run(
      key,
      target.toJson(),
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
    final revision = hasUnconfirmed('settings')
        ? settingsRevision
        : expectedRevision == 0
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
}
