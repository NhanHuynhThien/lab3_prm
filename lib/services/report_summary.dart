import '../models/ai_account.dart';
import '../models/auto_usage.dart';
import '../models/usage_session.dart';
import 'reporting_calendar.dart';

/// One grouped line of a report: sessions plus known totals.
/// A group whose sessions all lack a figure keeps it null, never 0.
class ReportRow {
  const ReportRow(this.label, this.sessions, this.tokens, this.costMicros);
  final String label;
  final int sessions;
  final int? tokens, costMicros;
}

/// Pure totals and groupings behind the export preview and the PDF, so no
/// widget or PDF builder does arithmetic on its own.
class ReportSummary {
  ReportSummary._({
    required this.sessions,
    required this.tokens,
    required this.costMicros,
    required this.knownTokenCount,
    required this.knownCostCount,
    required this.autoCount,
    required this.byDay,
    required this.byModel,
    required this.byPurpose,
  });

  factory ReportSummary.of(
    List<UsageSession> sessions, {
    String timezone = 'device',
  }) {
    final sorted = [...sessions]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return ReportSummary._(
      sessions: List.unmodifiable(sorted.reversed),
      tokens: _sum(sorted.map((s) => s.knownTokens)),
      costMicros: _sum(sorted.map((s) => s.costMicros)),
      knownTokenCount: sorted.where((s) => s.knownTokens != null).length,
      knownCostCount: sorted.where((s) => s.costMicros != null).length,
      autoCount: sorted.where((s) => isAutoId(s.id)).length,
      // Oldest day first so the table reads like a timeline.
      byDay: _group(
        sorted,
        (s) => ReportingCalendar.dayKey(s.occurredAt, timezone),
      ),
      byModel: _ranked(
        _group(
          sorted,
          (s) => s.modelId?.trim().isNotEmpty == true
              ? s.modelId!.trim()
              : 'Không rõ model',
        ),
      ),
      byPurpose: _ranked(_group(sorted, (s) => s.purpose.label)),
    );
  }

  /// Newest first.
  final List<UsageSession> sessions;
  final int? tokens, costMicros;
  final int knownTokenCount, knownCostCount, autoCount;
  final List<ReportRow> byDay, byModel, byPurpose;

  int get sessionCount => sessions.length;

  /// Cost columns only appear once some source reported a cost.
  bool get hasCost => knownCostCount > 0;

  ReportRow account(AIAccount account) {
    final own = sessions.where((s) => s.accountId == account.id).toList();
    return ReportRow(
      account.alias,
      own.length,
      own.isEmpty ? 0 : _sum(own.map((s) => s.knownTokens)),
      own.isEmpty ? 0 : _sum(own.map((s) => s.costMicros)),
    );
  }

  static int? _sum(Iterable<int?> values) {
    final known = values.whereType<int>();
    return known.isEmpty ? null : known.fold<int>(0, (a, b) => a + b);
  }

  static List<ReportRow> _group(
    List<UsageSession> sessions,
    String Function(UsageSession) key,
  ) {
    final groups = <String, List<UsageSession>>{};
    for (final s in sessions) {
      (groups[key(s)] ??= []).add(s);
    }
    return List.unmodifiable([
      for (final MapEntry(:key, :value) in groups.entries)
        ReportRow(
          key,
          value.length,
          _sum(value.map((s) => s.knownTokens)),
          _sum(value.map((s) => s.costMicros)),
        ),
    ]);
  }

  /// Largest token share first, then most sessions.
  static List<ReportRow> _ranked(List<ReportRow> rows) => List.unmodifiable(
    [...rows]..sort((a, b) {
      final byTokens = (b.tokens ?? -1).compareTo(a.tokens ?? -1);
      return byTokens != 0 ? byTokens : b.sessions.compareTo(a.sessions);
    }),
  );
}
