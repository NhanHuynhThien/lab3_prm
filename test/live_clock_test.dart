import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/dashboard_screen.dart' show QuotaRow;
import 'package:token_ledger/screens/history_screen.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/reporting_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

class ClockRepository extends MemoryRepository {
  int writes = 0;
  @override
  Future<void> save(LedgerData value) async {
    writes++;
    await super.save(value);
  }
}

void main() {
  late DateTime clock;
  late ClockRepository repository;
  late ProviderContainer container;
  var reads = 0;

  Future<void> open(
    WidgetTester tester,
    DateTime start, {
    Duration? resetIn,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    clock = start;
    reads = 0;
    repository = ClockRepository()
      ..data = createDemoSeed(start, timezone: 'device');
    if (resetIn != null) {
      final data = repository.data!;
      repository.data = data.copyWith(
        accounts: data.accounts
            .map(
              (a) => a.id == 'claude'
                  ? a.copyWith(
                      quota: QuotaSnapshot(
                        window: '5 giờ',
                        usedPercent: 65,
                        observedAt: start,
                        resetAt: start.add(resetIn),
                      ),
                    )
                  : a,
            )
            .toList(),
      );
    }
    container = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() {
          reads++;
          return clock;
        }),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await container.read(ledgerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final projection = ref.watch(dashboardProjectionProvider);
                return Column(
                  children: [
                    Text(
                      'month=${projection.now.month} count=${projection.summary.count} remaining=${projection.remaining}',
                    ),
                    QuotaRow(
                      account: ref
                          .watch(ledgerProvider)
                          .requireValue
                          .account('claude')!,
                      now: ref.watch(nowProvider),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'B07 midnight/month/year rolls totals and budget without reseeding',
    (tester) async {
      await open(tester, DateTime(2026, 12, 31, 23, 59, 50));
      expect(find.text('month=12 count=12 remaining=37160000'), findsOneWidget);
      clock = DateTime(2027, 1, 1);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('month=1 count=0 remaining=50000000'), findsOneWidget);
      expect(
        container.read(accountProjectionProvider('codex')).summary.count,
        0,
      );
      expect(
        container.read(historyProjectionProvider(('codex', null, ''))).sessions,
        isEmpty,
      );
      expect(
        container
            .read(accountProjectionProvider('codex'))
            .remainingBudgetMicros,
        25000000,
      );
      expect(repository.data!.sessions.length, 12);
      expect(repository.writes, 0);
      container.dispose();
    },
  );

  testWidgets(
    'B07 exact quota reset before minute becomes stale without a write',
    (tester) async {
      await open(
        tester,
        DateTime(2026, 10, 21, 10, 0, 5),
        resetIn: const Duration(seconds: 20),
      );
      expect(find.text('Còn 35%'), findsOneWidget);
      clock = clock.add(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(find.text('Cần cập nhật'), findsOneWidget);
      expect(find.text('Còn 100%'), findsNothing);
      expect(repository.data!.account('claude')!.quota!.usedPercent, 65);
      expect(repository.writes, 0);
      container.dispose();
    },
  );

  testWidgets(
    'B07 resume refreshes immediately; background pauses timer and retains selected range',
    (tester) async {
      await open(tester, DateTime(2026, 10, 31, 23, 59, 50));
      container.read(rangeProvider.notifier).select(UsageRange.week);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final old = container.read(nowProvider);
      final readsBefore = reads;
      clock = DateTime(2026, 11, 2, 9);
      await tester.pump(const Duration(hours: 34));
      expect(container.read(nowProvider), old);
      expect(reads, readsBefore);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(container.read(nowProvider), clock);
      expect(container.read(rangeProvider), UsageRange.week);
      expect(find.text('Cần cập nhật'), findsOneWidget);
      expect(repository.writes, 0);
      container.dispose();
    },
  );

  testWidgets(
    'B07 active clock rollback is detected at next minute without corrupting history',
    (tester) async {
      await open(tester, DateTime(2026, 11, 1, 12));
      clock = DateTime(2026, 10, 31, 12);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(container.read(nowProvider), clock);
      expect(container.read(ledgerProvider).hasError, isFalse);
      expect(container.read(dashboardProjectionProvider).summary.count, 0);
      expect(repository.data!.sessions.length, 12);
      expect(repository.writes, 0);
      container.dispose();
    },
  );

  testWidgets('B07 changing a quota reschedules the earlier reset deadline', (
    tester,
  ) async {
    await open(tester, DateTime(2026, 10, 21, 10, 0, 5));
    await container
        .read(ledgerProvider.notifier)
        .updateQuota(
          'claude',
          QuotaSnapshot(
            window: '5 giờ',
            usedPercent: 80,
            observedAt: clock,
            resetAt: clock.add(const Duration(seconds: 10)),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Còn 20%'), findsOneWidget);
    clock = clock.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Cần cập nhật'), findsOneWidget);
    expect(repository.writes, 1);
    container.dispose();
  });

  testWidgets('B07 unused clock disposes its timer', (tester) async {
    await open(tester, DateTime(2026, 10, 21, 10, 0, 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    final readsBefore = reads;
    clock = clock.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(reads, readsBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'B07 UTC year-boundary usage displays and edits on its local date',
    (tester) async {
      await open(tester, DateTime(2027, 1, 1, 0, 15));
      final utc = clock.toUtc();
      await container
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
        repository.data!.sessions
            .firstWhere((s) => s.id == 'utc-boundary')
            .occurredAt
            .isAtSameMomentAs(utc),
        isTrue,
      );
      container.dispose();
    },
  );

  testWidgets(
    'B03/B07 monthly account budget preserves null, zero and overrun',
    (tester) async {
      await open(tester, DateTime(2026, 10, 21, 10));
      final vm = container.read(ledgerProvider.notifier);
      final account = repository.data!.account('codex')!;
      await vm.saveAccount(account.copyWith(clearBudget: true));
      await tester.pumpAndSettle();
      expect(
        container
            .read(accountProjectionProvider('codex'))
            .remainingBudgetMicros,
        isNull,
      );
      await vm.saveAccount(account.copyWith(budgetMicros: 0));
      await tester.pumpAndSettle();
      expect(
        container
            .read(accountProjectionProvider('codex'))
            .remainingBudgetMicros,
        -5860000,
      );
      expect(
        container.read(accountProjectionProvider('codex')).budgetProgress,
        0,
      );
      await vm.saveAccount(account.copyWith(budgetMicros: 1000000));
      await tester.pumpAndSettle();
      expect(
        container
            .read(accountProjectionProvider('codex'))
            .remainingBudgetMicros,
        -4860000,
      );
      expect(repository.data!.sessions.length, 12);
      container.dispose();
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
