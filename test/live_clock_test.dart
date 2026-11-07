import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/dashboard_screen.dart' show QuotaRow;
import 'package:token_ledger/screens/history_screen.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/reporting_viewmodel.dart';

import 'support/live_clock_harness.dart';

void main() {
  late LiveClockTestHarness h;

  setUp(() {
    h = LiveClockTestHarness();
  });

  testWidgets(
    'B07 midnight/month/year rolls totals and budget without reseeding',
    (tester) async {
      await h.open(tester, DateTime(2026, 12, 31, 23, 59, 50));
      expect(find.text('month=12 count=12 remaining=37160000'), findsOneWidget);
      h.clock = DateTime(2027, 1, 1);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('month=1 count=0 remaining=50000000'), findsOneWidget);
      expect(
        h.container.read(accountProjectionProvider('codex')).summary.count,
        0,
      );
      expect(
        h.container
            .read(historyProjectionProvider(('codex', null, '')))
            .sessions,
        isEmpty,
      );
      expect(
        h.container
            .read(accountProjectionProvider('codex'))
            .remainingBudgetMicros,
        25000000,
      );
      expect(h.repository.data!.sessions.length, 12);
      expect(h.repository.writes, 0);
      h.container.dispose();
    },
  );

  testWidgets(
    'B07 exact quota reset before minute becomes stale without a write',
    (tester) async {
      await h.open(
        tester,
        DateTime(2026, 10, 21, 10, 0, 5),
        resetIn: const Duration(seconds: 20),
      );
      expect(find.text('Còn 35%'), findsOneWidget);
      h.clock = h.clock.add(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(find.text('Cần cập nhật'), findsOneWidget);
      expect(find.text('Còn 100%'), findsNothing);
      expect(h.repository.data!.account('claude')!.quota!.usedPercent, 65);
      expect(h.repository.writes, 0);
      h.container.dispose();
    },
  );

  testWidgets('B07 changing a quota reschedules the earlier reset deadline', (
    tester,
  ) async {
    await h.open(tester, DateTime(2026, 10, 21, 10, 0, 5));
    await h.container
        .read(ledgerProvider.notifier)
        .updateQuota(
          'claude',
          QuotaSnapshot(
            window: '5 giờ',
            usedPercent: 80,
            observedAt: h.clock,
            resetAt: h.clock.add(const Duration(seconds: 10)),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Còn 20%'), findsOneWidget);
    h.clock = h.clock.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Cần cập nhật'), findsOneWidget);
    expect(h.repository.writes, 1);
    h.container.dispose();
  });

  testWidgets(
    'B07 UTC year-boundary usage displays and edits on its local date',
    (tester) async {
      await h.open(tester, DateTime(2027, 1, 1, 0, 15));
      final utc = h.clock.toUtc();
      await h.container
          .read(ledgerProvider.notifier)
          .saveUsage(
            UsageSession(
              id: 'utc-boundary',
              accountId: 'codex',
              title: 'UTC year boundary',
              purpose: Purpose.code,
              occurredAt: utc,
            ),
          );
      Navigator.of(tester.element(find.byType(QuotaRow))).push(
        MaterialPageRoute<void>(
          builder: (_) => const HistoryScreen(accountId: 'codex'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('UTC year boundary'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('UTC year boundary'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('01/01/2027'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Sửa phiên'));
      await tester.tap(find.text('Sửa phiên'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Ngày sử dụng: 01/01/2027'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Ngày sử dụng: 01/01/2027'), findsOneWidget);
      await tester.tap(find.text('Lưu phiên sử dụng'));
      await tester.pumpAndSettle();
      expect(
        h.repository.data!.sessions
            .firstWhere((s) => s.id == 'utc-boundary')
            .occurredAt
            .isAtSameMomentAs(utc),
        isTrue,
      );
      h.container.dispose();
    },
  );

  test(
    'B07 UTC storage and local day chart use the identical half-open interval',
    () {
      final start = DateTime(2026, 11, 1);
      UsageSession record(String id, DateTime date, int cost) => UsageSession(
        id: id,
        accountId: 'a',
        title: id,
        purpose: Purpose.code,
        occurredAt: date.toUtc(),
        costMicros: cost,
      );
      final records = [
        record('before', start.subtract(const Duration(microseconds: 1)), 1),
        record('at-start', start, 2),
        record('end', DateTime(2026, 11, 2), 4),
      ];
      final period = UsageCalculator.filter(records, start);
      expect(period.map((s) => s.id), ['at-start']);
      expect(UsageCalculator.dailyCosts(period, start).last, 2);
      expect(UsageCalculator.dailyCosts(records, start).last, 2);
    },
  );

  test(
    'B07 seven local dates cross leap day/month without losing boundaries',
    () {
      final now = DateTime(2028, 3, 1, 10);
      final dates = List.generate(8, (i) => DateTime(2028, 3, 1 - i));
      final records = [
        for (var i = 0; i < dates.length; i++)
          UsageSession(
            id: '$i',
            accountId: 'a',
            title: 'day',
            purpose: Purpose.code,
            occurredAt: dates[i].toUtc(),
            costMicros: 100,
          ),
      ];
      final period = UsageCalculator.filter(
        records,
        now,
        range: UsageRange.week,
      );
      expect(period.length, 7);
      expect(UsageCalculator.dailyCosts(period, now), List.filled(7, 100));
      expect(UsageCalculator.filter(records, now).length, 1);
    },
  );
}
