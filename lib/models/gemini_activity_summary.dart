/// Only aggregate metadata survives import. Chat text and attachments are discarded.
class GeminiActivitySummary {
  GeminiActivitySummary({
    required this.importedAt,
    required this.periodStart,
    required Map<String, int> dailyCounts,
  }) : dailyCounts = Map.unmodifiable(dailyCounts);
  final DateTime importedAt, periodStart;
  final Map<String, int> dailyCounts;
  int get activityCount => dailyCounts.values.fold(0, (sum, n) => sum + n);
  int get activeDays => dailyCounts.length;
  int get busiestDayCount =>
      dailyCounts.values.fold(0, (max, n) => n > max ? n : max);
}
