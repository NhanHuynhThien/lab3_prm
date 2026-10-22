import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';

import 'support/demo_seed.dart';

import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/reporting_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;
import 'support/schema_v2_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 21, 10);

  AIAccount account({
    String id = 'real',
    String zone = 'Asia/Ho_Chi_Minh',
    int day = 1,
  }) => createSchemaTestAccount(now, id: id, zone: zone, day: day);

  UsageSession usage(
    String id,
    DateTime date, {
    String accountId = 'real',
    int? cost = 0,
    DataSource source = DataSource.manual,
  }) => createSchemaTestUsage(
    date,
    id,
    accountId: accountId,
    cost: cost,
    source: source,
  );

  test('quota replaces the same key, preserves other windows, stale does not reset, delete is scoped', () async {
    final repo = MemoryRepository()
      ..data = LedgerData(accounts: [account()], sessions: []);
    final c = createSchemaTestOwner(repo, now);
    await c.read(ledgerProvider.future);
    final vm = c.read(ledgerProvider.notifier);
    QuotaSnapshot q(String key, int used, int hours) => QuotaSnapshot(
      window: key,
      usedPercent: used,
      observedAt: now,
      resetAt: now.add(Duration(hours: hours)),
    );
    await vm.updateQuota('real', q('5h', 100, 5));
    await vm.updateQuota('real', q('week', 0, 24));
    await vm.updateQuota('real', q('5h', 40, 5));
    expect(repo.data!.accounts.single.quotaWindows.map((q) => q.usedPercent), [
      40,
      0,
    ]);
    await vm.updateQuota('real', q('5h', 40, 5).copyWith(window: 'Năm giờ'));
    await vm.updateQuota('real', q('Năm giờ', 40, 5));
    expect(repo.data!.accounts.single.quotaWindows.length, 2);
    expect(repo.data!.accounts.single.quotaWindows.first.windowKey, '5h');
    final snapshots = repo.data!.accounts.single.quotaWindows;
    expect(snapshots.first.isStale(now.add(const Duration(hours: 5))), isTrue);
    expect(snapshots.last.isStale(now.add(const Duration(hours: 5))), isFalse);
    expect(snapshots.first.usedPercent, 40);
    await vm.deleteQuota('real', '5h');
    await expectLater(
      vm.updateQuota('real', q('5h', 10, 5), requireExisting: true),
      throwsStateError,
    );
    expect(repo.data!.accounts.single.quotaWindows.single.window, 'week');
    await expectLater(
      vm.updateQuota('real', q('invalid', 10, 0)),
      throwsArgumentError,
    );
  });

  test('default changes never rewrite existing session model/purpose; provenance is immutable on edit', () async {
    final row = usage('x', now);
    final repo = MemoryRepository()
      ..data = LedgerData(accounts: [account()], sessions: [row]);
    final c = createSchemaTestOwner(repo, now);
    await c.read(ledgerProvider.future);
    final vm = c.read(ledgerProvider.notifier);
    await vm.saveAccount(
      account().copyWith(
        defaultModelId: 'example-model',
        defaultPurposes: [Purpose.review],
      ),
    );
    expect(repo.data!.sessions.single.modelId, isNull);
    expect(repo.data!.sessions.single.purpose, Purpose.code);
    await expectLater(
      vm.saveUsage(usage('x', now, source: DataSource.legacy)),
      throwsArgumentError,
    );
    expect(repo.data!.sessions.single.dataSource, DataSource.manual);
  });

  test('scope default excludes demo and legacy, provider drilldown equals projected totals', () async {
    final seed = createDemoSeed(now);
    final repo = MemoryRepository()
      ..data = LedgerData(
        accounts: [...seed.accounts, account()],
        sessions: [
          ...seed.sessions,
          usage('real-one', now, cost: 55),
          usage('old', now, cost: 1000, source: DataSource.legacy),
        ],
      );
    final c = createSchemaTestOwner(repo, now);
    await c.read(ledgerProvider.future);
    expect(c.read(effectiveDataScopeProvider), DataScope.manual);
    expect(c.read(dashboardProjectionProvider).summary.costMicros, 55);
    final analytics = c.read(analyticsProjectionProvider(UsageMetric.cost));
    expect(analytics.providers.single.value, 55);
    expect(
      c
          .read(providerHistoryProjectionProvider(('OpenAI', '')))
          .summary
          .costMicros,
      55,
    );
    c.read(dataScopeProvider.notifier).select(DataScope.demo);
    expect(c.read(dashboardProjectionProvider).summary.costMicros, 12840000);
    c.read(dataScopeProvider.notifier).select(DataScope.legacy);
    expect(c.read(dashboardProjectionProvider).summary.costMicros, 1000);
  });

  test('account cycle drilldown matches budget and search across calendar-month boundary', () async {
    final a = account(zone: 'UTC', day: 15);
    final repo = MemoryRepository()
      ..data = LedgerData(
        accounts: [a],
        sessions: [
          usage('outside', DateTime.utc(2026, 10, 14, 23, 59), cost: 99),
          usage('inside', DateTime.utc(2026, 10, 15), cost: 7),
        ],
      );
    final c = createSchemaTestOwner(repo, now);
    await c.read(ledgerProvider.future);
    expect(c.read(accountProjectionProvider(a.id)).summary.costMicros, 7);
    expect(
      c.read(accountCycleHistoryProvider((a.id, 'inside'))).summary.costMicros,
      7,
    );
    expect(
      c.read(accountCycleHistoryProvider((a.id, 'outside'))).sessions,
      isEmpty,
    );
    expect(c.read(dashboardProjectionProvider).spent, 7);
    expect(
      c
          .read(
            historyQueryProjectionProvider((
              accountId: a.id,
              purpose: Purpose.review,
              provider: 'OpenAI',
              search: '',
              useAccountCycle: true,
            )),
          )
          .sessions,
      isEmpty,
    );
    expect(
      c
          .read(
            historyQueryProjectionProvider((
              accountId: a.id,
              purpose: Purpose.code,
              provider: 'Anthropic',
              search: '',
              useAccountCycle: true,
            )),
          )
          .sessions,
      isEmpty,
    );
  });

  test('budget metadata from unrelated legacy accounts never inflates manual scope', () async {
    final legacy = LedgerData.fromJson(legacyFixture(now));
    final repo = MemoryRepository()
      ..data = legacy.copyWith(
        accounts: [...legacy.accounts, account()],
        sessions: [...legacy.sessions, usage('manual', now, cost: 7)],
      );
    final c = createSchemaTestOwner(repo, now);
    await c.read(ledgerProvider.future);
    expect(c.read(dashboardProjectionProvider).budget, 1000000);
    expect(c.read(dashboardProjectionProvider).spent, 7);
    c.read(dataScopeProvider.notifier).select(DataScope.legacy);
    expect(c.read(dashboardProjectionProvider).budget, 50000000);
    expect(c.read(dashboardProjectionProvider).spent, 12840000);
    repo.data = legacy.copyWith(sessions: []);
    final metadataOnly = createSchemaTestOwner(repo, now);
    await metadataOnly.read(ledgerProvider.future);
    expect(metadataOnly.read(effectiveDataScopeProvider), DataScope.legacy);
    expect(metadataOnly.read(dashboardProjectionProvider).budget, 50000000);
  });
}
