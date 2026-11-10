import 'dart:async';

import '../models/auto_usage.dart';
import '../models/ledger.dart';
import '../models/provider_usage.dart';
import '../services/analytics_service.dart';
import '../services/auto_ledger.dart';
import '../services/ledger_validation.dart';
import 'auto_usage_viewmodel.dart';
import 'cloud_ledger_mutations.dart';
import 'ledger_viewmodel.dart';
import 'provider_sources_viewmodel.dart';

const _managed = 'Tài khoản tự động do Companion quản lý, không sửa tay được.';

/// Joins Companion rows to the cloud ledger and routes edits of automatic
/// rows to their own store. Manual entities keep the transactional path.
mixin AutoLedgerLink on LedgerViewModel, CloudLedgerMutations {
  /// Re-runs [publish] whenever Companion rows or quota sources change.
  void watchAuto(void Function() publish) {
    ref.listen(autoUsageProvider, (_, _) => publish());
    try {
      ref.listen(providerSourcesProvider, (_, _) => publish());
    } catch (_) {
      // Quota sources unavailable in this build; rows still update.
    }
  }

  /// [manual] is already validated; a bad automatic row never blocks it.
  LedgerData withAuto(LedgerData manual) {
    List<ProviderUsage> sources;
    try {
      sources = ref.read(providerSourcesProvider);
    } catch (_) {
      sources = const []; // Quota is optional; rows still count.
    }
    try {
      final merged = AutoLedger.merge(
        manual,
        ref.read(autoUsageProvider),
        sources,
      );
      LedgerValidation.snapshot(merged);
      return merged;
    } catch (_) {
      return manual;
    }
  }

  void _guard(String accountId) {
    if (isAutoId(accountId)) throw StateError(_managed);
  }

  @override
  Future<void> saveAccount(AIAccount account, {int? expectedRevision}) {
    _guard(account.id);
    return super.saveAccount(account, expectedRevision: expectedRevision);
  }

  @override
  Future<void> archiveAccount(String id, bool archive) {
    _guard(id);
    return super.archiveAccount(id, archive);
  }

  @override
  Future<void> deleteAccount(String id) {
    _guard(id);
    return super.deleteAccount(id);
  }

  @override
  Future<void> updateQuota(
    String accountId,
    QuotaSnapshot quota, {
    bool requireExisting = false,
    int? expectedRevision,
  }) {
    _guard(accountId);
    return super.updateQuota(
      accountId,
      quota,
      requireExisting: requireExisting,
      expectedRevision: expectedRevision,
    );
  }

  @override
  Future<void> deleteQuota(String accountId, String windowKey) {
    _guard(accountId);
    return super.deleteQuota(accountId, windowKey);
  }

  @override
  Future<void> saveUsage(UsageSession session, {int? expectedRevision}) {
    if (!isAutoId(session.id) && !isAutoId(session.accountId)) {
      return super.saveUsage(session, expectedRevision: expectedRevision);
    }
    final entry = ref
        .read(autoUsageProvider)
        .where((e) => e.id == session.id && !e.hidden)
        .firstOrNull;
    if (entry == null) throw StateError('Không tìm thấy phiên tự động.');
    final current = entry.toSession();
    if (session.accountId != current.accountId ||
        !session.occurredAt.isAtSameMomentAs(current.occurredAt) ||
        session.inputTokens != current.inputTokens ||
        session.outputTokens != current.outputTokens ||
        session.costMicros != null ||
        session.modelId != current.modelId) {
      throw ArgumentError(
        'Phiên tự động chỉ sửa được mục đích, tên công việc và ghi chú.',
      );
    }
    LedgerValidation.usage(session);
    // An untouched default title follows later purpose changes.
    final title = entry.title == null && session.title == current.title
        ? ''
        : session.title;
    final edit = (purpose: session.purpose, title: title, note: session.note);
    return run(
      'auto/${session.id}',
      [session.purpose.name, title, session.note],
      (_) => ref.read(autoUsageProvider.notifier).edit(session.id, edit),
      event: ProductEvent.mutation('usage', 'update'),
    );
  }

  @override
  Future<void> deleteUsage(String id) {
    if (!isAutoId(id)) return super.deleteUsage(id);
    return run(
      'autoHide/$id',
      id,
      (_) => ref.read(autoUsageProvider.notifier).hide(id),
      event: ProductEvent.mutation('usage', 'delete'),
    );
  }
}
