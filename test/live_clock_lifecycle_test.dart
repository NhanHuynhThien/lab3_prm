import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    'B07 resume refreshes immediately; background pauses timer and retains selected range',
    (tester) async {
      await h.open(tester, DateTime(2026, 10, 31, 23, 59, 50));
      h.container.read(rangeProvider.notifier).select(UsageRange.week);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final old = h.container.read(nowProvider);
      final readsBefore = h.reads;
      h.clock = DateTime(2026, 11, 2, 9);
      await tester.pump(const Duration(hours: 34));
      expect(h.container.read(nowProvider), old);
      expect(h.reads, readsBefore);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(h.container.read(nowProvider), h.clock);
      expect(h.container.read(rangeProvider), UsageRange.week);
      expect(find.text('Cần cập nhật'), findsOneWidget);
      expect(h.repository.writes, 0);
      h.container.dispose();
    },
  );

  testWidgets(
    'B07 active clock rollback is detected at next minute without corrupting history',
    (tester) async {
      await h.open(tester, DateTime(2026, 11, 1, 12));
      h.clock = DateTime(2026, 10, 31, 12);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(h.container.read(nowProvider), h.clock);
      expect(h.container.read(ledgerProvider).hasError, isFalse);
      expect(h.container.read(dashboardProjectionProvider).summary.count, 0);
      expect(h.repository.data!.sessions.length, 12);
      expect(h.repository.writes, 0);
      h.container.dispose();
    },
  );

  testWidgets('B07 unused clock disposes its timer', (tester) async {
    await h.open(tester, DateTime(2026, 10, 21, 10, 0, 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    final readsBefore = h.reads;
    h.clock = h.clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(h.reads, readsBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'B03/B07 monthly account budget preserves null, zero and overrun',
    (tester) async {
      await h.open(tester, DateTime(2026, 10, 21, 10));
      final vm = h.container.read(ledgerProvider.notifier);
      final account = h.repository.data!.account('codex')!;
      await vm.saveAccount(account.copyWith(clearBudget: true));
      await tester.pumpAndSettle();
      expect(
        h.container
            .read(accountProjectionProvider('codex'))
            .remainingBudgetMicros,
        isNull,
      );
      await vm.saveAccount(account.copyWith(budgetMicros: 0));
      await tester.pumpAndSettle();
      expect(
        h.container
            .read(accountProjectionProvider('codex'))
            .remainingBudgetMicros,
        -5860000,
      );
      expect(
        h.container.read(accountProjectionProvider('codex')).budgetProgress,
        0,
      );
      await vm.saveAccount(account.copyWith(budgetMicros: 1000000));
      await tester.pumpAndSettle();
      expect(
        h.container
            .read(accountProjectionProvider('codex'))
            .remainingBudgetMicros,
        -4860000,
      );
      expect(h.repository.data!.sessions.length, 12);
      h.container.dispose();
    },
  );
}
