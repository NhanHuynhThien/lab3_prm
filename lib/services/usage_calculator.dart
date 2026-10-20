import '../models/ledger.dart';
import 'reporting_calendar.dart';

enum UsageRange {
  month('Tháng này'),
  week('7 ngày gần đây'),
  all('Tất cả thời gian');

  const UsageRange(this.label);
  final String label;
}

enum UsageMetric {
  cost('Chi phí'),
  tokens('Token'),
  sessions('Số phiên');

  const UsageMetric(this.label);
  final String label;
}

class UsageSummary {
  const UsageSummary(
    this.costMicros,
    this.tokens,
    this.count,
    this.unknownCost,
    this.unknownTokens, {
    this.actualCostMicros = 0,
    this.manualCostMicros = 0,
    this.unspecifiedCostMicros = 0,
  });
  final int costMicros, tokens, count, unknownCost, unknownTokens;
  final int actualCostMicros, manualCostMicros, unspecifiedCostMicros;
}

class PurposeShare {
  const PurposeShare(this.purpose, this.value, this.count);
  final Purpose purpose;
  final int value, count;
}

abstract final class UsageCalculator {
  static List<UsageSession> filter(
    List<UsageSession> sessions,
    DateTime now, {
    UsageRange range = UsageRange.month,
    String? accountId,
    Purpose? purpose,
    String search = '',
    String timezone = 'device',
    DataScope? scope,
    String? provider,
    List<AIAccount> accounts = const [],
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    now = ReportingCalendar.at(now, timezone);
    final start =
        periodStart ??
        switch (range) {
          UsageRange.month => ReportingCalendar.wall(
            timezone,
            now.year,
            now.month,
            1,
          ),
          UsageRange.week => ReportingCalendar.wall(
            timezone,
            now.year,
            now.month,
            now.day - 6,
          ),
          UsageRange.all => ReportingCalendar.wall(timezone, 2020, 1, 1),
        };
    final end =
        periodEnd ??
        ReportingCalendar.wall(timezone, now.year, now.month, now.day + 1);
    return sessions
        .where(
          (s) =>
              !s.occurredAt.isBefore(start) &&
              s.occurredAt.isBefore(end) &&
              (accountId == null || s.accountId == accountId) &&
              (purpose == null || s.purpose == purpose) &&
              (scope == null || scope.includes(s)) &&
              (provider == null ||
                  accounts.any(
                    (a) => a.id == s.accountId && a.provider == provider,
                  )) &&
              (search.isEmpty ||
                  s.title.toLowerCase().contains(search.toLowerCase())),
        )
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  static UsageSummary summarize(Iterable<UsageSession> sessions) {
    var cost = 0, tokens = 0, count = 0, missingCost = 0, missingTokens = 0;
    var actual = 0, manual = 0, unspecified = 0;
    for (final s in sessions) {
      count++;
      if (s.costMicros == null) {
        missingCost++;
      } else {
        cost += s.costMicros!;
        switch (s.effectiveCostBasis) {
          case CostBasis.actual:
            actual += s.costMicros!;
          case CostBasis.manual:
            manual += s.costMicros!;
          case CostBasis.unspecified:
          case CostBasis.unknown:
            unspecified += s.costMicros!;
        }
      }
      if (s.knownTokens == null) {
        missingTokens++;
      } else {
        tokens += s.knownTokens!;
      }
    }
    return UsageSummary(
      cost,
      tokens,
      count,
      missingCost,
      missingTokens,
      actualCostMicros: actual,
      manualCostMicros: manual,
      unspecifiedCostMicros: unspecified,
    );
  }

  static List<PurposeShare> shares(
    List<UsageSession> sessions,
    UsageMetric metric,
  ) {
    return Purpose.values
        .map((p) {
          final selected = sessions.where((s) => s.purpose == p);
          final summary = summarize(selected);
          return PurposeShare(p, switch (metric) {
            UsageMetric.cost => summary.costMicros,
            UsageMetric.tokens => summary.tokens,
            UsageMetric.sessions => summary.count,
          }, summary.count);
        })
        .where((p) => p.count > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  static List<UsageSession> inCycle(
    List<UsageSession> sessions,
    AIAccount account,
    DateTime now, {
    DataScope? scope,
  }) {
    final period = ReportingCalendar.cycle(
      now,
      account.timezone,
      account.cycleStartDay,
    );
    return sessions
        .where(
          (s) =>
              s.accountId == account.id &&
              (scope == null || scope.includes(s)) &&
              !s.occurredAt.isBefore(period.start) &&
              s.occurredAt.isBefore(period.end),
        )
        .toList();
  }

  static UsageMetric preferredMetric(List<UsageSession> sessions) =>
      sessions.any((s) => s.costMicros != null)
      ? UsageMetric.cost
      : UsageMetric.sessions;

  static List<int> dailyCosts(
    List<UsageSession> sessions,
    DateTime now, {
    String timezone = 'device',
  }) {
    now = ReportingCalendar.at(now, timezone);
    return List.generate(7, (i) {
      final d = ReportingCalendar.wall(
        timezone,
        now.year,
        now.month,
        now.day - 6 + i,
      );
      final end = ReportingCalendar.wall(timezone, d.year, d.month, d.day + 1);
      return summarize(
        sessions.where(
          (s) => !s.occurredAt.isBefore(d) && s.occurredAt.isBefore(end),
        ),
      ).costMicros;
    });
  }
}
