import 'dart:convert';
import 'dart:io';

import 'activity_summary.dart';
import 'auto_usage_rows.dart';
import 'companion_io.dart';
import 'model_usage.dart';

/// Local Codex or Claude Code session history for the last 30 days.
Future<Json> localModelUsage(
  String provider,
  DateTime now, {
  String? root,
}) async {
  root ??= provider == 'codex'
      ? '$homeDirectory/.codex/sessions'
      : '$homeDirectory/.claude/projects';
  final walked = await walkFiles(
    root,
    accepts: (name) => name.endsWith('.jsonl'),
    maxDepth: 7,
    descending: true,
  );
  var partial = walked.partial;
  final records = <UsageRecord>[];
  final seenSessions = <Object>{};
  for (final path in walked.files) {
    try {
      final stat = await File(path).stat();
      if (stat.modified.millisecondsSinceEpoch <
          now.millisecondsSinceEpoch - 30 * dayMs) {
        continue;
      }
      if (stat.type != FileSystemEntityType.file || stat.size > maxLogBytes) {
        partial = true;
        continue;
      }
      final text = await File(path).readAsString();
      if (provider == 'codex') {
        Object? session;
        try {
          final first = asJson(
            jsonDecode(const LineSplitter().convert(text).first),
          );
          final payload = asJson(first?['payload']);
          session = first?['type'] == 'session_meta' ? (payload?['id']) : null;
        } catch (_) {}
        if (session == null) {
          partial = true;
          continue;
        }
        // Rollout copies share the session_meta ID; do not count twice.
        if (!seenSessions.add(session)) continue;
      }
      records.addAll(
        provider == 'codex'
            ? codexModelRecords(text, now)
            : claudeModelRecords(text, now),
      );
    } catch (_) {
      partial = true;
    }
  }
  final unique = <String, UsageRecord>{
    for (var i = 0; i < records.length; i++)
      records[i].id ?? 'legacy:$i': records[i],
  }.values.toList();
  return {
    'activity': activitySummary(unique, now, partial: partial),
    'models': modelRows(unique),
    autoUsageKey: autoUsageRows(provider, unique, now),
    'modelsCoverage':
        '${partial ? 'Một phần dữ liệu. ' : ''}Lịch sử model trên máy trong 30 ngày; có thể gồm nhiều tài khoản, không phải tổng website.',
  };
}
