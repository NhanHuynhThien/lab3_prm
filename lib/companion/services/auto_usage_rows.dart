import 'activity_summary.dart';
import 'companion_io.dart';

const autoUsageKey = 'autoUsage';

/// The snapshot without per-task rows, which go to `auto_usage` instead.
Json stripAutoUsage(Json snapshot) => {
  ...snapshot,
  'providers': [
    for (final p in (snapshot['providers'] as List).cast<Json>())
      {...p}..remove(autoUsageKey),
  ],
};

/// Every provider's per-task rows in one list.
List<Json> autoUsageRowsOf(Json snapshot) => [
  for (final p in (snapshot['providers'] as List).cast<Json>())
    ...((p[autoUsageKey] as List?) ?? const []).cast<Json>(),
];

String _day(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}'
    '${local.month.toString().padLeft(2, '0')}'
    '${local.day.toString().padLeft(2, '0')}';

/// One row per CLI task per local calendar day, for
/// `users/{uid}/auto_usage/{id}`. Like the snapshot, nothing identifying
/// leaves the machine: the ID is a hash of the session/task, plus the
/// detected purpose label, model name, counts and times.
///
/// `outputTokens` is the reported output; `inputTokens` is the rest of the
/// reported total (input, cache and tool tokens), so input + output always
/// equals the total the snapshot shows.
///
/// Only whole local days inside the 30-day read window are emitted: the
/// oldest day is partly outside it and would shrink a row already saved.
List<Json> autoUsageRows(
  String provider,
  List<UsageRecord> records,
  DateTime now,
) {
  final cutoff = DateTime(
    now.year,
    now.month,
    now.day - 29,
  ).millisecondsSinceEpoch;
  final groups = <String, List<(UsageRecord, int)>>{};
  for (final r in records) {
    final at = parseMs(r.timestamp);
    final total = safeCount(r.total);
    if (at == null || at < cutoff || total == null || total == 0) continue;
    final session = r.session;
    if (session == null || session == '') continue;
    // Gemini CLI tags each reply, not each request: group by session there.
    final part = provider == 'google' ? '' : ':${r.task ?? 0}';
    final task = opaqueId('$provider:$session$part');
    final day = _day(DateTime.fromMillisecondsSinceEpoch(at));
    (groups['auto-$provider-$task-$day'] ??= []).add((r, at));
  }
  final rows = <Json>[];
  for (final MapEntry(key: id, value: items) in groups.entries) {
    var total = 0, output = 0, first = items.first.$2, last = first;
    final byModel = <String, int>{};
    for (final (r, at) in items) {
      if (!isSafeSum(total, r.total!)) break;
      total += r.total!;
      output += r.output ?? 0;
      if (at < first) first = at;
      if (at > last) last = at;
      if (validModel(r.model)) {
        byModel.update(
          r.model as String,
          (v) => v + r.total!,
          ifAbsent: () => r.total!,
        );
      }
    }
    if (output > total) output = total;
    // The task prompt counts as the start when it falls on this same day.
    final began = parseMs(items.first.$1.startedAt);
    final dayStart = DateTime.fromMillisecondsSinceEpoch(first);
    final midnight = DateTime(
      dayStart.year,
      dayStart.month,
      dayStart.day,
    ).millisecondsSinceEpoch;
    if (began != null && began < first && began >= midnight) first = began;
    final model = byModel.entries.isEmpty
        ? null
        : (byModel.entries.toList()..sort((a, b) => b.value - a.value))
              .first
              .key;
    rows.add({
      'id': id,
      'provider': provider,
      'detectedPurpose': items.first.$1.purpose,
      'model': model,
      'inputTokens': total - output,
      'outputTokens': output,
      'startedAt': isoMs(first),
      'occurredAt': isoMs(last),
    });
  }
  rows.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  return rows;
}
