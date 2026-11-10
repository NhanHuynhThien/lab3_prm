import 'activity_summary.dart';
import 'companion_io.dart';

bool _inPeriod(Object? date, DateTime now) {
  final at = parseMs(date);
  final nowMs = now.millisecondsSinceEpoch;
  return at != null && at <= nowMs && nowMs - at <= 30 * dayMs;
}

List<Json> modelRows(List<UsageRecord> records) {
  final result = <String, Json>{};
  for (final r in records) {
    if (!validModel(r.model) || safeCount(r.total) == null) continue;
    final value = result.putIfAbsent(
      r.model as String,
      () => {
        'model': r.model,
        'inputTokens': 0,
        'outputTokens': 0,
        'totalTokens': 0,
        'estimatedCostMicros': null,
        'billedCostMicros': null,
      },
    );
    for (final (key, raw) in [
      ('inputTokens', r.input),
      ('outputTokens', r.output),
      ('totalTokens', r.total),
    ]) {
      final current = value[key] as int?;
      value[key] = current == null || raw == null || !isSafeSum(current, raw)
          ? null
          : current + raw;
    }
  }
  final rows = result.values.where((v) => v['totalTokens'] != null).toList()
    ..sort(
      (a, b) => (b['totalTokens'] as int).compareTo(a['totalTokens'] as int),
    );
  return rows.take(100).toList();
}

String _userText(Json payload) {
  final meta = asJson(payload['internal_chat_message_metadata_passthrough']);
  final kinds = meta?['content_item_kinds'];
  final content = payload['content'];
  if (content is! List) return '';
  final parts = <String>[];
  for (var i = 0; i < content.length; i++) {
    final c = asJson(content[i]);
    if (c == null || (c['type'] != 'input_text' && c['type'] != 'text')) {
      continue;
    }
    if (kinds is List && (i >= kinds.length || kinds[i] != 'user.text')) {
      continue;
    }
    parts.add(c['text'] is String ? c['text'] as String : '');
  }
  return parts.join(' ').trim();
}

List<UsageRecord> codexModelRecords(String text, DateTime now) {
  Object? model, session, startedAt;
  var task = 0;
  var purpose = 'other';
  Json previous = {
    'input_tokens': 0,
    'output_tokens': 0,
    'total_tokens': 0,
    'cached_input_tokens': 0,
    'reasoning_output_tokens': 0,
  };
  final records = <UsageRecord>[];
  final responses = <String, UsageRecord>{};
  for (final row in jsonLines(text)) {
    final payload = asJson(row['payload']);
    final type = row['type'];
    if (type == 'session_meta') session = payload?['id'];
    if (type == 'turn_context') model = payload?['model'];
    if (type == 'event_msg' && payload?['type'] == 'user_message') {
      task++;
      purpose = classifyPurpose(payload!['message']);
      startedAt = row['timestamp'];
    }
    if (type == 'response_item' &&
        payload?['type'] == 'message' &&
        payload!['role'] == 'user') {
      final content = _userText(payload);
      if (content.isNotEmpty) {
        task++;
        purpose = classifyPurpose(content);
        startedAt = row['timestamp'];
      }
    }
    if (type == 'token_usage_record') {
      final u = asJson(payload?['usage']);
      final responseId = payload?['response_id'];
      if (payload?['thread_id'] == session &&
          responseId is String &&
          safeCount(u?['total_tokens']) != null &&
          _inPeriod(row['timestamp'], now)) {
        responses[responseId] = UsageRecord(
          id: responseId,
          model: model,
          session: session,
          task: payload!['turn_id'] ?? task,
          purpose: purpose,
          startedAt: startedAt,
          timestamp: row['timestamp'],
          input: safeCount(u!['input_tokens']),
          output: safeCount(u['output_tokens']),
          total: safeCount(u['total_tokens']),
          cached: safeCount(u['cached_input_tokens']),
          cacheWrite: safeCount(u['cache_write_input_tokens']),
          reasoning: safeCount(u['reasoning_output_tokens']),
        );
      }
    }
    if (type != 'event_msg' || payload?['type'] != 'token_count') continue;
    final total = asJson(asJson(payload!['info'])?['total_token_usage']);
    if (total == null || safeCount(total['total_tokens']) == null) continue;
    int? diff(String key) {
      final a = safeCount(total[key]), b = safeCount(previous[key]);
      return a != null && b != null ? (a - b < 0 ? 0 : a - b) : null;
    }

    final record = UsageRecord(
      model: model,
      session: session,
      task: task,
      purpose: purpose,
      startedAt: startedAt,
      timestamp: row['timestamp'],
      input: diff('input_tokens'),
      output: diff('output_tokens'),
      total: diff('total_tokens'),
      cached: diff('cached_input_tokens'),
      reasoning: diff('reasoning_output_tokens'),
    );
    previous = total;
    if ((record.total ?? 0) > 0 && _inPeriod(row['timestamp'], now)) {
      records.add(record);
    }
  }
  // New schema has per-response usage; never add its cumulative mirror again.
  return responses.isNotEmpty ? responses.values.toList() : records;
}

List<UsageRecord> claudeModelRecords(String text, DateTime now) {
  final messages = <String, (Json usage, Json meta)>{};
  var task = 0;
  var purpose = 'other';
  Object? startedAt;
  const usageFields = [
    'input_tokens',
    'cache_creation_input_tokens',
    'cache_read_input_tokens',
    'output_tokens',
  ];
  for (final row in jsonLines(text)) {
    final msg = asJson(row['message']);
    if (row['type'] == 'user') {
      final c = msg?['content'];
      final content = c is String
          ? c
          : c is List
          ? c
                .map(asJson)
                .where((p) => p?['type'] == 'text')
                .map((p) => '${p!['text']}')
                .join(' ')
          : '';
      if (content.isNotEmpty) {
        task++;
        purpose = classifyPurpose(content);
        startedAt = row['timestamp'];
      }
    }
    final usage = asJson(msg?['usage']);
    if (row['type'] != 'assistant' ||
        msg?['id'] is! String ||
        !validModel(msg!['model']) ||
        usage == null ||
        !_inPeriod(row['timestamp'], now)) {
      continue;
    }
    final key = '${msg['id']}:${msg['model']}';
    final old = messages[key]?.$1 ?? const <String, Object?>{};
    final next = Map<String, Object?>.of(old);
    for (final field in usageFields) {
      final v = safeCount(usage[field]);
      if (v != null) {
        final before = (old[field] as int?) ?? 0;
        next[field] = v > before ? v : before;
      }
    }
    messages[key] = (
      next,
      {
        'model': msg['model'],
        'session': row['sessionId'],
        'task': task,
        'purpose': purpose,
        'startedAt': startedAt,
        'timestamp': row['timestamp'],
      },
    );
  }
  return [
    for (final MapEntry(key: id, value: (u, meta)) in messages.entries)
      if (u['input_tokens'] != null && u['output_tokens'] != null)
        _claudeRecord(id, u, meta),
  ];
}

UsageRecord _claudeRecord(String id, Json u, Json meta) {
  final input =
      (u['input_tokens'] as int) +
      ((u['cache_creation_input_tokens'] as int?) ?? 0) +
      ((u['cache_read_input_tokens'] as int?) ?? 0);
  return UsageRecord(
    id: id,
    model: meta['model'],
    session: meta['session'],
    task: meta['task'],
    purpose: meta['purpose'] as String,
    startedAt: meta['startedAt'],
    timestamp: meta['timestamp'],
    input: input,
    output: u['output_tokens'] as int,
    total: input + (u['output_tokens'] as int),
    cached: safeCount(u['cache_read_input_tokens']),
    cacheWrite: safeCount(u['cache_creation_input_tokens']),
  );
}
