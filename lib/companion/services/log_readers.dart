import 'dart:convert';
import 'dart:io';

import 'activity_summary.dart';
import 'auto_usage_rows.dart';
import 'companion_io.dart';
import 'model_usage.dart';

Json _claudeEmpty() => {
  'id': 'claude',
  'status': 'setup',
  'source': 'Claude Code status line',
  'coverage': 'Chưa có status line. Xem hướng dẫn kết nối Claude Code.',
  'observedAt': null,
  'plan': null,
  'windows': <Object>[],
  'totalTokens': null,
  'contextTokens': null,
  'estimatedCostMicros': null,
  'subscriptionFeeMicros': null,
  'billedCostMicros': null,
};

/// Reads the allowlisted Claude Code status-line metrics written locally by
/// `tool/provider_bridge/claude.mjs`. Unknown properties never pass through.
Future<Json> readClaude({String? dir}) async {
  try {
    final raw = asJson(
      jsonDecode(
        await File('${dir ?? companionStateDir}/claude-metrics.json')
            .readAsString(),
      ),
    )!;
    final observed = parseMs(raw['observedAt']);
    // Last entry per window wins; output order is 5 giờ, then 7 ngày.
    final byLabel = <String, Json?>{'5 giờ': null, '7 ngày': null};
    for (final w in (raw['windows'] as List? ?? const []).map(asJson)) {
      final label = w?['label'] == '7 ngày' ? '7 ngày' : '5 giờ';
      final used = w?['usedPercent'];
      final reset = parseMs(w?['resetsAt']);
      byLabel[label] = used is! num || used < 0 || used > 100 || reset == null
          ? null
          : {'label': label, 'usedPercent': used, 'resetsAt': isoMs(reset)};
    }
    final windows = byLabel.values.whereType<Json>().toList();
    final context = safeCount(raw['contextTokens']);
    final cost = safeCount(raw['estimatedCostMicros']);
    final ready = windows.isNotEmpty || context != null || cost != null;
    return {
      ..._claudeEmpty(),
      'status': ready ? 'ready' : 'setup',
      'coverage': 'Context hiện tại và ước tính phiên Code; không phải tổng usage website.',
      'observedAt': observed == null ? null : isoMs(observed),
      'windows': windows,
      'contextTokens': context,
      'estimatedCostMicros': cost,
    };
  } catch (_) {
    return _claudeEmpty();
  }
}

/// Gemini CLI writes either a JSON document or append-only JSONL patches.
List<Json> geminiMessages(String text) {
  try {
    final doc = asJson(jsonDecode(text));
    final list = doc?['messages'];
    if (list is List) return list.map(asJson).whereType<Json>().toList();
  } catch (_) {}
  var messages = <Object?, Json>{};
  for (final row in jsonLines(text)) {
    final set = asJson(row[r'$set'])?['messages'];
    final patch = asJson(row[r'$patch']);
    if (set is List) {
      messages = {
        for (final m in set.map(asJson).whereType<Json>()) m['id']: m,
      };
    } else if (row[r'$rewindTo'] != null) {
      var after = false;
      for (final id in messages.keys.toList()) {
        if (after) messages.remove(id);
        if (id == row[r'$rewindTo']) after = true;
      }
    } else if (patch?['removeIds'] is List) {
      for (final id in patch!['removeIds'] as List) {
        messages.remove(id);
      }
    } else if (row['type'] == 'gemini' && row['id'] is String) {
      messages[row['id']] = row;
    }
  }
  return messages.values.toList();
}

Future<Json> readGemini(DateTime now, {String? root}) async {
  final walked = await walkFiles(
    root ?? '$homeDirectory/.gemini/tmp',
    accepts: (n) => RegExp(r'^session-.*\.jsonl?$').hasMatch(n),
    maxDepth: 4,
    deepIsPartial: false,
  );
  var truncated = walked.partial;
  var tokens = 0, known = 0;
  int? observed;
  final records = <UsageRecord>[];
  final seen = <String>{};
  final nowMs = now.millisecondsSinceEpoch;
  for (final file in walked.files) {
    try {
      final stat = await File(file).stat();
      if (stat.type != FileSystemEntityType.file || stat.size > maxLogBytes) {
        truncated = true;
        continue;
      }
      for (final row in geminiMessages(await File(file).readAsString())) {
        final date = parseMs(row['timestamp']);
        final t = asJson(row['tokens']);
        final amount = safeCount(t?['total']);
        final id = row['id'];
        if (row['type'] != 'gemini' ||
            id is! String ||
            amount == null ||
            date == null ||
            date > nowMs ||
            nowMs - date > 30 * dayMs) {
          continue;
        }
        // Session files can be copied/resumed; never count a message twice.
        if (!seen.add(id)) continue;
        if (!isSafeSum(tokens, amount)) {
          truncated = true;
          continue;
        }
        tokens += amount;
        known++;
        records.add(
          UsageRecord(
            model: row['model'],
            input: safeCount(t!['input']),
            output: safeCount(t['output']),
            total: amount,
            timestamp: row['timestamp'],
            session: file,
            task: id,
            cached: safeCount(t['cached']),
            reasoning: safeCount(t['thoughts']),
          ),
        );
        if (observed == null || date > observed) observed = date;
      }
    } catch (_) {
      truncated = true;
    }
  }
  return {
    'id': 'google',
    'status': known > 0 ? 'ready' : 'setup',
    'plan': null,
    'source': 'Gemini CLI · lịch sử 30 ngày',
    'coverage':
        '${truncated ? 'Một phần lịch sử. ' : ''}Chỉ phiên CLI lưu trên máy; chưa đọc quota/hoá đơn AI Pro hay usage website.',
    'observedAt': observed == null ? null : isoMs(observed),
    'totalTokens': known > 0 ? tokens : null,
    'contextTokens': null,
    'windows': <Object>[],
    'activity': activitySummary(records, now, partial: truncated),
    'models': modelRows(records),
    autoUsageKey: autoUsageRows('google', records, now),
    'modelsCoverage': 'Lịch sử Gemini CLI trên máy, 30 ngày; không xác minh cùng owner với Google login.',
    'estimatedCostMicros': null,
    'subscriptionFeeMicros': null,
    'billedCostMicros': null,
  };
}
