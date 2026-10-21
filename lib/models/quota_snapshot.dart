import 'ledger_enums.dart';

class QuotaSnapshot {
  const QuotaSnapshot({
    required this.window,
    required this.usedPercent,
    required this.observedAt,
    required this.resetAt,
    this.unit = 'percent',
    String? windowKey,
    this.source = DataSource.manual,
    this.sourceLabel = '',
    this.note = '',
  }) : windowKey = windowKey ?? window;

  final String window, unit, windowKey, sourceLabel, note;
  final DataSource source;
  final int usedPercent;
  final DateTime observedAt, resetAt;

  int get remainingPercent => (100 - usedPercent).clamp(0, 100);
  bool isStale(DateTime now) => !now.isBefore(resetAt);

  QuotaSnapshot copyWith({
    String? window,
    String? windowKey,
    int? usedPercent,
    DateTime? observedAt,
    DateTime? resetAt,
    DataSource? source,
    String? sourceLabel,
    String? note,
  }) => QuotaSnapshot(
    window: window ?? this.window,
    windowKey: windowKey ?? this.windowKey,
    usedPercent: usedPercent ?? this.usedPercent,
    observedAt: observedAt ?? this.observedAt,
    resetAt: resetAt ?? this.resetAt,
    source: source ?? this.source,
    sourceLabel: sourceLabel ?? this.sourceLabel,
    note: note ?? this.note,
  );

  Map<String, dynamic> toJson() => {
    'window': window,
    'unit': unit,
    'windowKey': windowKey,
    'source': source.name,
    'sourceLabel': sourceLabel,
    'note': note,
    'usedPercent': usedPercent,
    'observedAt': observedAt.toUtc().toIso8601String(),
    'resetAt': resetAt.toUtc().toIso8601String(),
  };

  factory QuotaSnapshot.fromJson(Map<String, dynamic> j) {
    if (j['unit'] != 'percent') {
      throw const FormatException('Đơn vị quota chưa được hỗ trợ.');
    }
    return QuotaSnapshot(
      window: j['window'] as String,
      windowKey: j['windowKey'] as String?,
      source: j.containsKey('source')
          ? DataSource.values.byName(j['source'] as String)
          : DataSource.legacy,
      sourceLabel: j['sourceLabel'] as String? ?? '',
      note: j['note'] as String? ?? '',
      usedPercent: j['usedPercent'] as int,
      observedAt: decodeTimestamp(j['observedAt']),
      resetAt: decodeTimestamp(j['resetAt']),
    );
  }
}
