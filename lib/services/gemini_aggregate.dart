import '../models/ledger.dart';

/// Deliberately excludes titles, notes, account names, emails and chat content.
class GeminiAggregate {
  GeminiAggregate(Iterable<UsageSession> source, DateTime now) {
    final sessions = source
        .where((s) => !s.isDemo && !s.occurredAt.isAfter(now))
        .toList();
    final times = sessions.map((s) => s.occurredAt.toUtc()).toList()..sort();
    sessionCount = sessions.length;
    final known = sessions.where((s) => s.knownTokens != null).toList();
    final costs = sessions.where((s) => s.costMicros != null).toList();
    totalTokens = known.fold(0, (n, s) => n + s.knownTokens!);
    knownTokenSessions = known.length;
    knownCostSessions = costs.length;
    costMicros = costs.isEmpty
        ? null
        : costs.fold<int>(0, (n, s) => n + s.costMicros!);
    start = times.isEmpty ? now.toUtc() : times.first;
    end = now.toUtc();
    final details = [
      for (final purpose in Purpose.values)
        () {
          final group = sessions.where((s) => s.purpose == purpose).toList();
          final stamps = group.map((s) => s.occurredAt.toUtc()).toList()
            ..sort();
          return {
            'purpose': purpose.name,
            'sessions': group.length,
            'knownTokens': group.fold<int>(
              0,
              (n, s) => n + (s.knownTokens ?? 0),
            ),
            'knownCostMicros': group.fold<int>(
              0,
              (n, s) => n + (s.costMicros ?? 0),
            ),
            'unknownTokenSessions': group
                .where((s) => s.knownTokens == null)
                .length,
            'unknownCostSessions': group
                .where((s) => s.costMicros == null)
                .length,
            'firstAt': stamps.isEmpty ? null : stamps.first.toIso8601String(),
            'lastAt': stamps.isEmpty ? null : stamps.last.toIso8601String(),
          };
        }(),
    ];
    payload = {
      'consent': true,
      'periodStart': start.toIso8601String(),
      'periodEnd': end.toIso8601String(),
      'inputTokens': known.length == sessions.length
          ? known.fold<int>(0, (n, s) => n + s.inputTokens!)
          : null,
      'outputTokens': known.length == sessions.length
          ? known.fold<int>(0, (n, s) => n + s.outputTokens!)
          : null,
      'totalTokens': totalTokens,
      'costMicros': costMicros,
      'source': 'manual',
      'purposes': [
        for (final d in details)
          {'purpose': d['purpose'], 'tokens': d['knownTokens']},
      ],
      'coverage': {
        'sessions': sessions.length,
        'knownTokenSessions': known.length,
        'knownCostSessions': costs.length,
      },
      'details': details,
    };
  }
  late final Map<String, dynamic> payload;
  late final int sessionCount,
      totalTokens,
      knownTokenSessions,
      knownCostSessions;
  late final int? costMicros;
  late final DateTime start, end;
  bool get eligible =>
      sessionCount > 0 &&
      knownTokenSessions > 0 &&
      end.difference(start).inDays <= 365;
}
