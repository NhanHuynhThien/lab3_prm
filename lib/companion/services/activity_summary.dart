import 'companion_io.dart';

/// One usage event projected from a local CLI log. No prompt, title, path,
/// account identity or raw session ID leaves the companion.
class UsageRecord {
  UsageRecord({
    this.id,
    this.model,
    this.session,
    this.task,
    this.purpose = 'other',
    this.startedAt,
    required this.timestamp,
    this.input,
    this.output,
    required this.total,
    this.cached,
    this.cacheWrite,
    this.reasoning,
  });
  final String? id;
  final Object? model;
  final Object? session;
  final Object? task;
  final String purpose;
  final Object? startedAt;
  final Object? timestamp;
  final int? input, output, total, cached, cacheWrite, reasoning;

  int? field(String name) => switch (name) {
    'total' => total,
    'input' => input,
    'output' => output,
    'cached' => cached,
    'cacheWrite' => cacheWrite,
    _ => reasoning,
  };
}

const _purposes = {
  'code',
  'debug',
  'test',
  'review',
  'design',
  'research',
  'write',
  'learn',
};

final _purposeRules = <String, RegExp>{
  'debug': RegExp(r'\b(debug|bug|fix|error|crash|loi|sua loi|lag)\b'),
  'test': RegExp(r'\b(test|testing|verify|kiem thu|kiem tra)\b'),
  'review': RegExp(r'\b(review|audit|danh gia|ra soat)\b'),
  'design': RegExp(
    r'\b(design|redesign|css|layout|ui|ux|thiet ke|giao dien)\b',
  ),
  'research': RegExp(r'\b(research|search|investigate|nghien cuu|tim hieu)\b'),
  'write': RegExp(r'\b(write|document|draft|viet|tai lieu|bao cao)\b'),
  'learn': RegExp(r'\b(explain|learn|teach|giai thich|hoc)\b'),
  'code': RegExp(
    r'\b(code|implement|build|refactor|function|lap trinh|tich hop)\b',
  ),
};

const _folded = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};
final _foldMap = {
  for (final entry in _folded.entries)
    for (final rune in entry.value.runes) rune: entry.key.codeUnitAt(0),
};

/// Lowercases and removes Vietnamese diacritics, like NFD + strip in Node.
String foldText(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if (rune >= 0x300 && rune <= 0x36f) continue;
    out.writeCharCode(_foldMap[rune] ?? rune);
  }
  return out.toString();
}

String classifyPurpose(Object? text) {
  if (text is! String) return 'other';
  final value = foldText(text.length > 32000 ? text.substring(0, 32000) : text);
  final scores = [
    for (final e in _purposeRules.entries)
      (e.key, e.value.allMatches(value).length),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return scores[0].$2 > 0 && scores[0].$2 != scores[1].$2
      ? scores[0].$1
      : 'other';
}

const _fields = {
  'totalTokens': 'total',
  'inputTokens': 'input',
  'outputTokens': 'output',
  'cachedInputTokens': 'cached',
  'cacheWriteTokens': 'cacheWrite',
  'reasoningTokens': 'reasoning',
};

void _add(Json target, UsageRecord r) {
  target['eventCount'] = ((target['eventCount'] as int?) ?? 0) + 1;
  for (final MapEntry(:key, :value) in _fields.entries) {
    final v = r.field(value);
    final hasKey = target.containsKey(key);
    final current = target[key] as int?;
    target[key] =
        (hasKey && current == null) || v == null || !isSafeSum(current ?? 0, v)
        ? null
        : (current ?? 0) + v;
  }
}

final _modelPattern = RegExp(r'^[a-zA-Z0-9._:/-]{1,128}$');
bool validModel(Object? model) =>
    model is String && _modelPattern.hasMatch(model);

Json? activitySummary(
  List<UsageRecord> records,
  DateTime now, {
  bool partial = false,
}) {
  final nowMs = now.millisecondsSinceEpoch;
  final start = nowMs - 30 * dayMs;
  final rows = records.where((r) {
    final at = parseMs(r.timestamp);
    return safeCount(r.total) != null &&
        r.total! > 0 &&
        at != null &&
        at >= start &&
        at <= nowMs;
  }).toList();
  if (rows.isEmpty) return null;
  final Json totals = {for (final key in _fields.keys) key: 0, 'eventCount': 0};
  final tasks = <String, Json>{}, days = <String, Json>{};
  final purposes = <String, Json>{};
  final taskModels = <String, Set<String>>{};
  final sessions = <Object>{};
  for (final r in rows) {
    _add(totals, r);
    final purpose = _purposes.contains(r.purpose) ? r.purpose : 'other';
    final at = parseMs(r.timestamp)!;
    final day = isoMs(at).substring(0, 10);
    _add(days.putIfAbsent(day, () => {'day': day}), r);
    _add(purposes.putIfAbsent(purpose, () => {'purpose': purpose}), r);
    final session = r.session;
    if (session == null || session == '') continue;
    sessions.add(session);
    final id = opaqueId('$session:${r.task ?? 0}');
    final t = tasks.putIfAbsent(
      id,
      () => {
        'id': id,
        'sessionId': opaqueId(session),
        'purpose': purpose,
        'startedAt': null,
        'endedAt': r.timestamp,
      },
    );
    final models = taskModels.putIfAbsent(id, () => <String>{});
    if (validModel(r.model)) models.add(r.model as String);
    final began = parseMs(r.startedAt);
    if (began != null && began >= start && began <= at) {
      final current = parseMs(t['startedAt']);
      if (current == null || began < current) t['startedAt'] = isoMs(began);
    }
    if (at > (parseMs(t['endedAt']) ?? 0)) t['endedAt'] = r.timestamp;
    _add(t, r);
  }
  final sorted = tasks.values.toList()
    ..sort(
      (a, b) =>
          (parseMs(b['endedAt']) ?? 0).compareTo(parseMs(a['endedAt']) ?? 0),
    );
  int tokens(Json v) => (v['totalTokens'] as int?) ?? 0;
  return {
    'periodStart': isoMs(start),
    'periodEnd': isoMs(nowMs),
    'partial': partial,
    ...totals,
    'sessionCount': sessions.length,
    'taskCount': tasks.length,
    'activeDays': days.length,
    'daily': days.values.toList()
      ..sort((a, b) => (a['day'] as String).compareTo(b['day'] as String)),
    'purposes': purposes.values.toList()
      ..sort((a, b) => tokens(b).compareTo(tokens(a))),
    'tasks': [
      for (final t in sorted.take(60))
        {
          ...t,
          'models': (taskModels[t['id']]!.toList()..sort()).take(100).toList(),
          'elapsedSeconds': t['startedAt'] == null
              ? null
              : ((parseMs(t['endedAt'])! - parseMs(t['startedAt'])!) / 1000)
                    .floor(),
        },
    ],
    'omittedTasks': sorted.length > 60 ? sorted.length - 60 : 0,
    'billedCostMicros': null,
    'method': 'Mục đích suy luận bằng từ khóa của yêu cầu; nhãn Khác khi thiếu hoặc mơ hồ. Thời lượng từ yêu cầu đến token cuối, gồm chờ/nghỉ; không phải thời gian GPU. Cache là phần của input; reasoning là phần của output. Không có hóa đơn hay đơn giá đã xác nhận.',
  };
}
