import '../models/auto_usage.dart';
import '../models/ledger.dart';
import '../models/provider_usage.dart';

/// Folds Companion auto-imports into the user's ledger so every screen reads
/// one set of accounts and sessions. Pure: no SDK calls.
abstract final class AutoLedger {
  static LedgerData merge(
    LedgerData manual,
    List<AutoUsageEntry> entries,
    List<ProviderUsage> sources,
  ) {
    final visible = entries.where((e) => !e.hidden).toList();
    final accounts = <AIAccount>[];
    for (final MapEntry(key: id, value: meta) in autoProviders.entries) {
      final own = entries.where((e) => e.provider == id).toList();
      final source = sources.where((s) => s.id == id).firstOrNull;
      final windows = source == null ? <QuotaSnapshot>[] : quotas(source);
      if (own.isEmpty && windows.isEmpty) continue;
      final first = own.isEmpty
          ? source!.observedAt!
          : own
                .map((e) => e.startedAt ?? e.occurredAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
      accounts.add(
        AIAccount(
          id: autoAccountId(id),
          alias: meta.product,
          provider: meta.provider,
          product: meta.product,
          billingMode: BillingMode.subscription,
          plan: _clip(source?.plan ?? '', 60),
          createdAt: first,
          quotaWindows: windows,
          dataSource: DataSource.companion,
        ),
      );
    }
    return manual.copyWith(
      accounts: [...manual.accounts.where((a) => !isAutoId(a.id)), ...accounts],
      sessions: [
        ...manual.sessions.where((s) => !isAutoId(s.id)),
        ...visible.map((e) => e.toSession()),
      ],
    );
  }

  /// Current quota windows reported by a ready source, in ledger form.
  static List<QuotaSnapshot> quotas(ProviderUsage source) {
    final observed = source.observedAt;
    if (source.status != 'ready' || observed == null) return const [];
    final keys = <String>{}, labels = <String>{};
    return [
      for (final w in source.windows)
        if (w.resetsAt.isAfter(observed) &&
            keys.add(_clip(w.label, 128)) &&
            labels.add(_clip(w.displayLabel, 60).trim().toLowerCase()))
          QuotaSnapshot(
            window: _clip(w.displayLabel, 60),
            windowKey: _clip(w.label, 128),
            usedPercent: w.usedPercent.round().clamp(0, 100),
            observedAt: observed,
            resetAt: w.resetsAt,
            source: DataSource.companion,
            sourceLabel: _clip(source.source, 120),
          ),
    ];
  }

  static String _clip(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);
}
