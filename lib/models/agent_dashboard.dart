import 'provider_usage.dart';

class AgentDashboard {
  AgentDashboard(List<ProviderUsage> sources, this.now) {
    connected = sources
        .where((s) => s.status == 'ready' || s.observedAt != null)
        .toList();
    freshCount = connected
        .where((s) => s.status == 'ready' && !s.stale(now))
        .length;
    attention = connected
        .where(
          (s) =>
              s.status != 'ready' ||
              s.stale(now) ||
              s.windows.any((w) => (s.remaining(w, now) ?? 0) <= 25),
        )
        .length;
    quotaCount = connected.fold(
      0,
      (n, s) => n + s.windows.where((w) => s.remaining(w, now) != null).length,
    );
    lastUpdated = connected
        .map((s) => s.observedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
  }
  final DateTime now;
  late final List<ProviderUsage> connected;
  late final int freshCount, attention, quotaCount;
  late final DateTime? lastUpdated;

  ProviderQuota? limiting(ProviderUsage source) {
    final rows =
        source.windows.where((w) => source.remaining(w, now) != null).toList()
          ..sort((a, b) => b.usedPercent.compareTo(a.usedPercent));
    return rows.firstOrNull;
  }
}
