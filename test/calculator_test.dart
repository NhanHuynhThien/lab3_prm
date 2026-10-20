import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/utils/formatters.dart';

void main() {
  final now = DateTime(2026, 10, 19, 10);
  test('demo summaries reconcile with entries and preserve missing values', () {
    final data = createDemoSeed(now);
    final summary = UsageCalculator.summarize(data.sessions);
    expect(summary.costMicros, 12840000);
    expect(summary.count, 12);
    expect(summary.tokens, 286000);
    expect(summary.unknownCost, 1);
    expect(summary.unknownTokens, 1);
    final shares = UsageCalculator.shares(data.sessions, UsageMetric.cost);
    expect(shares.fold<int>(0, (s, p) => s + p.value), summary.costMicros);
  });
  test('missing token is not zero; known zero stays zero', () {
    final unknown = UsageSession(
      id: 'a',
      accountId: 'a',
      title: 'test',
      purpose: Purpose.code,
      occurredAt: now,
    );
    final zero = UsageSession(
      id: 'b',
      accountId: 'a',
      title: 'test',
      purpose: Purpose.code,
      occurredAt: now,
      inputTokens: 0,
      outputTokens: 0,
      costMicros: 0,
    );
    expect(unknown.knownTokens, isNull);
    expect(zero.knownTokens, 0);
    expect(UsageCalculator.summarize([unknown, zero]).unknownCost, 1);
  });
  test('period boundary and account filtering exclude unrelated records', () {
    final data = createDemoSeed(now);
    final previous = UsageSession(
      id: 'prior',
      accountId: 'codex',
      title: 'prior',
      purpose: Purpose.code,
      occurredAt: DateTime(2026, 9, 30),
    );
    final next = UsageSession(
      id: 'next',
      accountId: 'codex',
      title: 'next',
      purpose: Purpose.code,
      occurredAt: DateTime(2026, 10, 20),
    );
    final result = UsageCalculator.filter(
      [...data.sessions, previous, next],
      now,
      accountId: 'codex',
    );
    expect(result.length, 4);
    expect(UsageCalculator.summarize(result).costMicros, 5860000);
  });
  test(
    'USD parser preserves micros and rejects negative or invalid values',
    () {
      expect(parseUsd('0.000001'), 1);
      expect(parseUsd('20,12'), 20120000);
      expect(parseUsd(''), isNull);
      expect(() => parseUsd('-1'), throwsFormatException);
      expect(() => parseUsd('NaN'), throwsFormatException);
      expect(() => parseUsd('0.1234567'), throwsFormatException);
      expect(usdInput(20000000), '20');
    },
  );
  test('JSON round trip keeps nulls, quota and timestamps', () {
    final data = createDemoSeed(now);
    final copy = LedgerData.fromJson(data.toJson());
    expect(copy.accounts.first.quota!.remainingPercent, 35);
    expect(copy.sessions.last.costMicros, isNull);
    expect(
      copy.sessions.first.occurredAt.isAtSameMomentAs(
        data.sessions.first.occurredAt,
      ),
      isTrue,
    );
  });
  test('quota becomes stale at reset, without inventing a reset allowance', () {
    final quota = createDemoSeed(now).accounts.first.quota!;
    expect(quota.isStale(now), isFalse);
    expect(quota.isStale(quota.resetAt), isTrue);
    expect(quota.remainingPercent, 35);
  });
  test('seed remains in current month at midnight on day one', () {
    final date = DateTime(2026, 11, 1, 0, 1);
    expect(
      UsageCalculator.filter(createDemoSeed(date).sessions, date).length,
      12,
    );
  });
  test(
    'UTC timestamps display the same local calendar date/time as projections',
    () {
      final local = DateTime(2027, 1, 1, 0, 15);
      expect(shortDate(local.toUtc()), '01/01');
      expect(shortTime(local.toUtc()), '00:15');
      expect(shortDate(DateTime(2028, 2, 29, 23, 59).toUtc()), '29/02');
    },
  );
}
