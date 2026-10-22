import 'provider_model_usage.dart';
import 'provider_activity.dart';

const providerNames = {
  'codex': 'ChatGPT / Codex',
  'claude': 'Claude',
  'google': 'Gemini CLI',
  'antigravity': 'Antigravity',
  'gemini-web': 'Gemini web',
};

class ProviderQuota {
  const ProviderQuota(
    this.label,
    this.usedPercent,
    this.resetsAt, {
    this.group,
    this.window,
  });
  final String label;
  final double usedPercent;
  final DateTime resetsAt;
  final String? group, window;

  String get groupLabel => group ?? label.split(' · ').first;
  String get windowLabel => switch (window) {
    '5h' => '5 giờ',
    'weekly' => '7 ngày',
    _ => displayLabel,
  };

  String get displayLabel {
    final match = RegExp(r'^(.*?) · (\d+) phút$').firstMatch(label);
    if (match == null) return label;
    final minutes = int.parse(match[2]!);
    final duration = minutes > 0 && minutes % 1440 == 0
        ? '${minutes ~/ 1440} ngày'
        : minutes > 0 && minutes % 60 == 0
        ? '${minutes ~/ 60} giờ'
        : '$minutes phút';
    return match[1] == 'codex' ? duration : '${match[1]} · $duration';
  }

  factory ProviderQuota.fromJson(Map<String, dynamic> json) {
    final value = json['usedPercent'];
    if (value is! num || !value.isFinite || value < 0 || value > 100) {
      throw const FormatException('Quota không hợp lệ.');
    }
    return ProviderQuota(
      _text(json['label'], 100),
      value.toDouble(),
      _date(json['resetsAt']),
      group: json['group'] == null ? null : _text(json['group'], 100),
      window: json['window'] == null ? null : _text(json['window'], 32),
    );
  }
}

class ProviderUsage {
  const ProviderUsage({
    required this.id,
    required this.status,
    required this.source,
    required this.coverage,
    required this.observedAt,
    required this.windows,
    this.plan,
    this.activity,
    this.totalTokens,
    this.contextTokens,
    this.estimatedCostMicros,
    this.models = const [],
    this.modelsCoverage = 'Chưa có nguồn thống kê model.',
  });
  final String id, status, source, coverage;
  final String? plan;
  final ProviderActivity? activity;
  final DateTime? observedAt;
  final int? totalTokens, contextTokens, estimatedCostMicros;
  final List<ProviderQuota> windows;
  final List<ProviderModelUsage> models;
  final String modelsCoverage;
  String get name => providerNames[id]!;

  bool stale(DateTime now) =>
      observedAt == null || now.difference(observedAt!).inMinutes >= 15;

  double? remaining(ProviderQuota window, DateTime now) =>
      status != 'ready' || stale(now) || !window.resetsAt.isAfter(now)
      ? null
      : 100 - window.usedPercent;

  ProviderUsage disconnected() => ProviderUsage(
    id: id,
    status: 'error',
    source: source,
    coverage: 'Nguồn tạm ngắt. Bản đã đọc: $coverage',
    observedAt: observedAt,
    windows: windows,
    plan: plan,
    activity: activity,
    totalTokens: totalTokens,
    contextTokens: contextTokens,
    estimatedCostMicros: estimatedCostMicros,
    models: models,
    modelsCoverage: modelsCoverage,
  );

  factory ProviderUsage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (!providerNames.containsKey(id) ||
        !['ready', 'setup', 'error'].contains(json['status']) ||
        json['windows'] is! List ||
        (json['windows'] as List).length > 20) {
      throw const FormatException('Nguồn đồng bộ không hợp lệ.');
    }
    final observed = json['observedAt'] == null
        ? null
        : _date(json['observedAt']);
    final rawModels = json['models'] ?? [];
    if (rawModels is! List || rawModels.length > 100) {
      throw const FormatException('Danh sách model không hợp lệ.');
    }
    final models = rawModels
        .map(
          (m) =>
              ProviderModelUsage.fromJson(Map<String, dynamic>.from(m as Map)),
        )
        .toList();
    if (models.map((m) => m.model).toSet().length != models.length) {
      throw const FormatException('Model nguồn bị trùng.');
    }
    if (json['status'] == 'ready' && observed == null) {
      throw const FormatException('Thiếu thời điểm nguồn dữ liệu.');
    }
    return ProviderUsage(
      id: id as String,
      status: json['status'] as String,
      source: _text(json['source'], 180),
      coverage: _text(json['coverage'], 400),
      activity: json['activity'] == null
          ? null
          : ProviderActivity.fromJson(
              Map<String, dynamic>.from(json['activity'] as Map),
            ),
      plan: json['plan'] == null ? null : _text(json['plan'], 60),
      observedAt: observed,
      totalTokens: _count(json['totalTokens']),
      contextTokens: _count(json['contextTokens']),
      estimatedCostMicros: _count(json['estimatedCostMicros']),
      models: List.unmodifiable(models),
      modelsCoverage: json['modelsCoverage'] == null
          ? 'Chưa có nguồn thống kê model.'
          : _text(json['modelsCoverage'], 400),
      windows: List.unmodifiable(
        (json['windows'] as List).map(
          (w) => ProviderQuota.fromJson(Map<String, dynamic>.from(w as Map)),
        ),
      ),
    );
  }
}

class ProviderSnapshot {
  const ProviderSnapshot(this.collectedAt, this.providers);
  final DateTime collectedAt;
  final List<ProviderUsage> providers;

  factory ProviderSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 ||
        json['providers'] is! List ||
        ((json['providers'] as List).length < 3 ||
            (json['providers'] as List).length > 5)) {
      throw const FormatException('Snapshot chưa được hỗ trợ.');
    }
    final rows = (json['providers'] as List)
        .map((r) => ProviderUsage.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    if (rows.map((r) => r.id).toSet().length != rows.length ||
        !rows.map((r) => r.id).toSet().containsAll([
          'codex',
          'claude',
          'google',
        ])) {
      throw const FormatException('Nguồn dữ liệu bị trùng.');
    }
    return ProviderSnapshot(
      _date(json['collectedAt']),
      List.unmodifiable(rows),
    );
  }
}

int? _count(Object? value) {
  if (value == null) return null;
  if (value is! int || value < 0 || value > 9007199254740991) {
    throw const FormatException('Số liệu đồng bộ không hợp lệ.');
  }
  return value;
}

String _text(Object? value, int max) {
  if (value is! String || value.isEmpty || value.length > max) {
    throw const FormatException('Nhãn nguồn không hợp lệ.');
  }
  return value;
}

DateTime _date(Object? value) {
  if (value is! String || !value.endsWith('Z')) {
    throw const FormatException('Thời điểm phải là UTC.');
  }
  final date = DateTime.tryParse(value);
  if (date == null) throw const FormatException('Thời điểm không hợp lệ.');
  return date.toUtc();
}
