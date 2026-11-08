import 'provider_usage.dart';

/// How close a quota is to running out, for colouring and alerts.
enum QuotaLevel { normal, warning, alert }

class AgentDashboard {
  AgentDashboard(List<ProviderUsage> sources, this.now) {
    connected = sources
        .where((s) => s.status == 'ready' || s.observedAt != null)
        .toList();
    freshCount = connected
        .where((s) => s.status == 'ready' && !s.stale(now))
        .length;
    attention = connected.where(needsAttention).length;
    quotaCount = connected.fold(
      0,
      (n, s) => n + s.windows.where((w) => s.remaining(w, now) != null).length,
    );
    lastUpdated = connected
        .map((s) => s.observedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
  }

  /// Remaining quota share at or below which an agent needs attention.
  static const attentionRemainingPercent = 25;

  /// Used share from which a quota is shown as a warning.
  static const warnUsedPercent = 100 - attentionRemainingPercent;

  final DateTime now;
  late final List<ProviderUsage> connected;
  late final int freshCount, attention, quotaCount;
  late final DateTime? lastUpdated;

  /// Not ready, stale, or a current quota window nearly used up.
  bool needsAttention(ProviderUsage s) =>
      s.status != 'ready' ||
      s.stale(now) ||
      s.windows.any(
        (w) => (s.remaining(w, now) ?? 0) <= attentionRemainingPercent,
      );

  ProviderQuota? limiting(ProviderUsage source) {
    final rows =
        source.windows.where((w) => source.remaining(w, now) != null).toList()
          ..sort((a, b) => b.usedPercent.compareTo(a.usedPercent));
    return rows.firstOrNull;
  }

  /// [alertAt] is the user's own alert percent for this agent, if any.
  static QuotaLevel level(double usedPercent, int? alertAt) =>
      alertAt != null && usedPercent >= alertAt
      ? QuotaLevel.alert
      : usedPercent >= warnUsedPercent
      ? QuotaLevel.warning
      : QuotaLevel.normal;
}
