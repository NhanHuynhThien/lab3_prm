import '../models/ledger.dart';

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
    this.unknownTokens,
  );
  final int costMicros, tokens, count, unknownCost, unknownTokens;
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
  }) {
    final start = switch (range) {
      UsageRange.month => DateTime(now.year, now.month),
      UsageRange.week => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6)),
      UsageRange.all => DateTime(2000),
    };
    final end = DateTime(now.year, now.month, now.day + 1);
    return sessions
        .where(
          (s) =>
              !s.occurredAt.isBefore(start) &&
              s.occurredAt.isBefore(end) &&
              (accountId == null || s.accountId == accountId) &&
              (purpose == null || s.purpose == purpose) &&
              (search.isEmpty ||
                  s.title.toLowerCase().contains(search.toLowerCase())),
        )
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  static UsageSummary summarize(Iterable<UsageSession> sessions) {
    var cost = 0, tokens = 0, count = 0, missingCost = 0, missingTokens = 0;
    for (final s in sessions) {
      count++;
      if (s.costMicros == null) {
        missingCost++;
      } else {
        cost += s.costMicros!;
      }
      if (s.knownTokens == null) {
        missingTokens++;
      } else {
        tokens += s.knownTokens!;
      }
    }
    return UsageSummary(cost, tokens, count, missingCost, missingTokens);
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

  static List<int> dailyCosts(List<UsageSession> sessions, DateTime now) =>
      List.generate(7, (i) {
        final d = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: 6 - i));
        return summarize(
          sessions.where(
            (s) =>
                s.occurredAt.year == d.year &&
                s.occurredAt.month == d.month &&
                s.occurredAt.day == d.day,
          ),
        ).costMicros;
      });
}
