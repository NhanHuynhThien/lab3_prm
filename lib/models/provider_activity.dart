import 'ledger_enums.dart';

class ActivityTokens {
  const ActivityTokens(
    this.total,
    this.input,
    this.output,
    this.cached,
    this.cacheWrite,
    this.reasoning,
    this.events,
  );
  final int total, events;
  final int? input, output, cached, cacheWrite, reasoning;
  factory ActivityTokens.fromJson(Map<String, dynamic> j) => ActivityTokens(
    _number(j['totalTokens'])!,
    _number(j['inputTokens'], optional: true),
    _number(j['outputTokens'], optional: true),
    _number(j['cachedInputTokens'], optional: true),
    _number(j['cacheWriteTokens'], optional: true),
    _number(j['reasoningTokens'], optional: true),
    _number(j['eventCount'])!,
  );
}

class ActivityPurpose {
  const ActivityPurpose(this.purpose, this.tokens);
  final Purpose purpose;
  final ActivityTokens tokens;
  factory ActivityPurpose.fromJson(Map<String, dynamic> j) => ActivityPurpose(
    Purpose.values.firstWhere(
      (p) => p.name == j['purpose'],
      orElse: () => throw const FormatException('Mục đích không hợp lệ.'),
    ),
    ActivityTokens.fromJson(j),
  );
}

class ActivityDay {
  const ActivityDay(this.day, this.tokens);
  final DateTime day;
  final ActivityTokens tokens;
  factory ActivityDay.fromJson(Map<String, dynamic> j) {
    final value = j['day'];
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Ngày thống kê không hợp lệ.');
    }
    return ActivityDay(_date('${value}T00:00:00Z'), ActivityTokens.fromJson(j));
  }
}

class ActivityTask {
  const ActivityTask({
    required this.id,
    required this.sessionId,
    required this.purpose,
    required this.models,
    required this.tokens,
    required this.endedAt,
    this.startedAt,
    this.elapsedSeconds,
  });
  final String id, sessionId;
  final Purpose purpose;
  final List<String> models;
  final ActivityTokens tokens;
  final DateTime? startedAt;
  final DateTime endedAt;
  final int? elapsedSeconds;
  factory ActivityTask.fromJson(Map<String, dynamic> j) {
    final start = j['startedAt'] == null ? null : _date(j['startedAt']);
    final end = _date(j['endedAt']);
    final seconds = _number(j['elapsedSeconds'], optional: true);
    if ((start != null && start.isAfter(end)) ||
        (seconds != null &&
            (start == null || seconds != end.difference(start).inSeconds))) {
      throw const FormatException('Thời lượng công việc không hợp lệ.');
    }
    final models = _list(j['models'], 100).map((m) {
      if (m is! String || !RegExp(r'^[a-zA-Z0-9._:/-]{1,128}$').hasMatch(m)) {
        throw const FormatException('Model công việc không hợp lệ.');
      }
      return m;
    }).toList();
    return ActivityTask(
      id: _id(j['id']),
      sessionId: _id(j['sessionId']),
      purpose: ActivityPurpose.fromJson(j).purpose,
      models: List.unmodifiable(models),
      tokens: ActivityTokens.fromJson(j),
      startedAt: start,
      endedAt: end,
      elapsedSeconds: seconds,
    );
  }
}

class ProviderActivity {
  const ProviderActivity({
    required this.start,
    required this.end,
    required this.partial,
    required this.tokens,
    required this.sessionCount,
    required this.taskCount,
    required this.activeDays,
    required this.omittedTasks,
    required this.purposes,
    required this.daily,
    required this.tasks,
    required this.method,
  });
  final DateTime start, end;
  final bool partial;
  final ActivityTokens tokens;
  final int sessionCount, taskCount, activeDays, omittedTasks;
  final List<ActivityPurpose> purposes;
  final List<ActivityDay> daily;
  final List<ActivityTask> tasks;
  final String method;
  double share(ActivityTokens value) =>
      tokens.total == 0 ? 0 : value.total / tokens.total;
  List<ActivityTask> tasksFor(Purpose? purpose) =>
      tasks.where((t) => purpose == null || t.purpose == purpose).toList();
  int get recentSevenTokens => daily
      .where(
        (d) => !d.day.isBefore(
          DateTime.utc(
            end.year,
            end.month,
            end.day,
          ).subtract(const Duration(days: 6)),
        ),
      )
      .fold(0, (n, d) => n + d.tokens.total);
  factory ProviderActivity.fromJson(Map<String, dynamic> j) {
    final start = _date(j['periodStart']), end = _date(j['periodEnd']);
    if (start.isAfter(end) ||
        end.difference(start) > const Duration(days: 31) ||
        j['partial'] is! bool ||
        j['method'] is! String ||
        (j['method'] as String).length > 800) {
      throw const FormatException('Phạm vi hoạt động không hợp lệ.');
    }
    final daily = _list(
      j['daily'],
      31,
    ).map((r) => ActivityDay.fromJson(_map(r))).toList();
    final purposes = _list(
      j['purposes'],
      9,
    ).map((r) => ActivityPurpose.fromJson(_map(r))).toList();
    final tasks = _list(
      j['tasks'],
      60,
    ).map((r) => ActivityTask.fromJson(_map(r))).toList();
    final totals = ActivityTokens.fromJson(j);
    if (daily.map((d) => d.day).toSet().length != daily.length ||
        purposes.map((p) => p.purpose).toSet().length != purposes.length ||
        tasks.map((t) => t.id).toSet().length != tasks.length ||
        daily.fold<int>(0, (n, d) => n + d.tokens.total) != totals.total ||
        purposes.fold<int>(0, (n, p) => n + p.tokens.total) != totals.total ||
        tasks.any((t) => t.endedAt.isAfter(end) || t.endedAt.isBefore(start))) {
      throw const FormatException('Phân bổ token không khớp.');
    }
    return ProviderActivity(
      start: start,
      end: end,
      partial: j['partial'],
      tokens: totals,
      sessionCount: _number(j['sessionCount'])!,
      taskCount: _number(j['taskCount'])!,
      activeDays: _number(j['activeDays'])!,
      omittedTasks: _number(j['omittedTasks'])!,
      purposes: List.unmodifiable(purposes),
      daily: List.unmodifiable(daily),
      tasks: List.unmodifiable(tasks),
      method: j['method'],
    );
  }
}

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map);
List _list(Object? value, int max) {
  if (value is! List || value.length > max) {
    throw const FormatException('Danh sách hoạt động không hợp lệ.');
  }
  return value;
}

int? _number(Object? value, {bool optional = false}) {
  if (value == null && optional) return null;
  if (value is! int || value < 0 || value > 9007199254740991) {
    throw const FormatException('Số liệu hoạt động không hợp lệ.');
  }
  return value;
}

String _id(Object? value) {
  if (value is! String || !RegExp(r'^[a-f0-9]{16}$').hasMatch(value)) {
    throw const FormatException('Mã công việc không hợp lệ.');
  }
  return value;
}

DateTime _date(Object? value) {
  if (value is! String ||
      !value.endsWith('Z') ||
      DateTime.tryParse(value) == null) {
    throw const FormatException('Thời điểm hoạt động không hợp lệ.');
  }
  return decodeTimestamp(value).toUtc();
}
