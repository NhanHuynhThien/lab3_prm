import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/services/ledger_repository.dart';
import 'package:token_ledger/services/ledger_validation.dart';
import 'package:token_ledger/services/reporting_calendar.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/reporting_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;
import 'local_repository_test.dart' show FaultyPreferences;

class DelayedMigrationPreferences extends FaultyPreferences {
  final backupStarted = Completer<void>();
  final releaseBackup = Completer<void>();
  @override
  Future<bool> setString(String key, String value) async {
    if (key == LocalLedgerRepository.migrationBackupKey) {
      if (!backupStarted.isCompleted) {
        backupStarted.complete();
      }
      await releaseBackup.future;
    }
    return super.setString(key, value);
  }
}

Map<String, dynamic> legacyFixture(DateTime now) {
  final seed = createDemoSeed(now, timezone: 'device');
  return {
    'schemaVersion': 1,
    'accounts': seed.accounts
        .map(
          (a) => {
            'id': a.id,
            'alias': a.alias,
            'provider': a.provider,
            'product': a.product,
            'billingMode': a.billingMode.name,
            'plan': a.plan,
            'archived': a.archived,
            'budgetMicros': a.budgetMicros,
            'createdAt': a.createdAt.toIso8601String(),
            'quota': a.quota == null
                ? null
                : {
                    'window': a.quota!.window,
                    'usedPercent': a.quota!.usedPercent,
                    'observedAt': a.quota!.observedAt.toIso8601String(),
                    'resetAt': a.quota!.resetAt.toIso8601String(),
                  },
          },
        )
        .toList(),
    'sessions': seed.sessions
        .map(
          (s) => {
            'id': s.id,
            'accountId': s.accountId,
            'title': s.title,
            'purpose': s.purpose.name,
            'occurredAt': s.occurredAt.toIso8601String(),
            'inputTokens': s.inputTokens,
            'outputTokens': s.outputTokens,
            'costMicros': s.costMicros,
            'note': s.note,
          },
        )
        .toList(),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 21, 10);
  const key = LocalLedgerRepository.storageKey;
  const backup = LocalLedgerRepository.migrationBackupKey;

  AIAccount account({
    String id = 'real',
    String zone = 'Asia/Ho_Chi_Minh',
    int day = 1,
  }) => AIAccount(
    id: id,
    alias: 'Theo dõi công việc',
    provider: 'OpenAI',
    product: 'Codex',
    billingMode: BillingMode.api,
    plan: '',
    createdAt: now,
    timezone: zone,
    cycleStartDay: day,
    budgetMicros: 1000000,
  );
  UsageSession usage(
    String id,
    DateTime date, {
    String accountId = 'real',
    int? cost = 0,
    DataSource source = DataSource.manual,
  }) => UsageSession(
    id: id,
    accountId: accountId,
    title: 'Công việc $id',
    purpose: Purpose.code,
    occurredAt: date,
    costMicros: cost,
    dataSource: source,
    isDemo: source == DataSource.demo,
  );
  ProviderContainer owner(MemoryRepository repository) {
    final c = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('v1 migration backs up exact raw value, preserves totals/null/time and never guesses provenance', () async {
    final raw = jsonEncode(legacyFixture(now));
    final prefs = FaultyPreferences()..values[key] = raw;
    final repository = LocalLedgerRepository(prefs);
    final data = (await repository.load())!;
    expect(jsonDecode(prefs.values[backup] as String)['value'], raw);
    expect(jsonDecode(prefs.values[key] as String)['schemaVersion'], 2);
    expect(data.reportingTimezone, 'device');
    expect(UsageCalculator.summarize(data.sessions).costMicros, 12840000);
    expect(UsageCalculator.summarize(data.sessions).tokens, 286000);
    expect(data.sessions.last.costMicros, isNull);
    expect(data.sessions.first.dataSource, DataSource.legacy);
    expect(data.sessions.first.effectiveCostBasis, CostBasis.unspecified);
    expect(data.sessions.every((s) => !s.isDemo && s.modelId == null), isTrue);
    expect(data.accounts.first.quotaWindows.length, 1);
    expect(data.accounts.first.quota!.source, DataSource.legacy);
    expect(data.accounts.first.defaultPurposes, isEmpty);
    final once = prefs.values[key];
    expect((await repository.load())!.toJson(), data.toJson());
    expect(prefs.values[key], once);
    expect(jsonDecode(prefs.values[backup] as String)['value'], raw);
  });

  for (final failBackup in [true, false]) {
    test(
      'migration ${failBackup ? 'backup' : 'replace'} failure keeps v1 and retry is lossless',
      () async {
        final raw = jsonEncode(legacyFixture(now));
        final prefs = FaultyPreferences()
          ..values[key] = raw
          ..failKey = failBackup ? backup : key;
        final repo = LocalLedgerRepository(prefs);
        await expectLater(repo.load(), throwsA(isA<LedgerStorageException>()));
        expect(prefs.values[key], raw);
        if (failBackup) expect(prefs.values[backup], isNull);
        prefs.failKey = null;
        final data = (await repo.load())!;
        expect(data.sessions.length, 12);
        expect(jsonDecode(prefs.values[backup] as String)['value'], raw);
      },
    );
  }

  test(
    'corrupt legacy data is never backed up as valid migration or overwritten',
    () async {
      final j = legacyFixture(now);
      (j['sessions'] as List).first['costMicros'] = -1;
      final raw = jsonEncode(j);
      final prefs = FaultyPreferences()..values[key] = raw;
      await expectLater(
        LocalLedgerRepository(prefs).load(),
        throwsA(isA<LedgerStorageException>()),
      );
      expect(prefs.values[key], raw);
      expect(prefs.values[backup], isNull);
    },
  );

  test(
    'concurrent reload shares migration and later save cannot be overwritten',
    () async {
      final raw = jsonEncode(legacyFixture(now));
      final prefs = DelayedMigrationPreferences()..values[key] = raw;
      final repo = LocalLedgerRepository(prefs);
      final first = repo.load();
      await prefs.backupStarted.future;
      final second = repo.load();
      expect(identical(first, second), isTrue);
      final next = LedgerData.fromJson(legacyFixture(now))
          .copyWith(reportingTimezone: 'UTC');
      final write = repo.save(next);
      expect(prefs.values[key], raw);
      prefs.releaseBackup.complete();
      await Future.wait([first, second, write]);
      expect(
        jsonDecode(prefs.values[key] as String)['reportingTimezone'],
        'UTC',
      );
      expect(jsonDecode(prefs.values[backup] as String)['value'], raw);
    },
  );

  test(
    'cost basis breakdown sums once and keeps unknown out of known totals',
    () {
      UsageSession row(String id, int? cost, CostBasis basis) => UsageSession(
        id: id,
        accountId: 'real',
        title: id,
        purpose: Purpose.code,
        occurredAt: now,
        costMicros: cost,
        costBasis: basis,
      );
      final summary = UsageCalculator.summarize([
        row('actual', 2, CostBasis.actual),
        row('manual', 3, CostBasis.manual),
        row('old', 5, CostBasis.unspecified),
        row('unknown', null, CostBasis.unknown),
      ]);
      expect(summary.costMicros, 10);
      expect(summary.actualCostMicros, 2);
      expect(summary.manualCostMicros, 3);
      expect(summary.unspecifiedCostMicros, 5);
      expect(summary.unknownCost, 1);
    },
  );

  test('model/default purposes and quota collections round trip immutable with explicit clears', () {
    final defaults = [Purpose.review, Purpose.test];
    final q = QuotaSnapshot(
      window: '5 giờ',
      usedPercent: 0,
      observedAt: now,
      resetAt: now.add(const Duration(hours: 5)),
      sourceLabel: 'Trang usage',
      note: 'Quan sát thủ công',
    );
    final a = account().copyWith(
      defaultModelId: 'model-do-nguoi-dung-nhap',
      defaultPurposes: defaults,
      quotaWindows: [q],
    );
    defaults.clear();
    expect(a.defaultPurposes.length, 2);
    expect(() => a.defaultPurposes.clear(), throwsUnsupportedError);
    expect(() => a.quotaWindows.clear(), throwsUnsupportedError);
    final loaded = LedgerData.fromJson(
      LedgerData(accounts: [a], sessions: []).toJson(),
    ).accounts.single;
    expect(loaded.defaultModelId, a.defaultModelId);
    expect(loaded.quota!.sourceLabel, 'Trang usage');
    expect(loaded.quota!.unit, 'percent');
    expect(
      () => QuotaSnapshot.fromJson({...q.toJson(), 'unit': 'tokens'}),
      throwsFormatException,
    );
    expect(
      loaded
          .copyWith(
            clearDefaultModel: true,
            defaultPurposes: [],
            quotaWindows: [],
          )
          .defaultModelId,
      isNull,
    );
    expect(loaded.copyWith(quotaWindows: []).quotaWindows, isEmpty);
  });

  test('all persisted timestamps serialize UTC without moving the instant', () {
    final j = legacyFixture(now);
    j['sessions'][0]['occurredAt'] = '2026-10-21T17:30:00+07:00';
    final data = LedgerData.fromJson(j);
    expect(data.sessions.first.occurredAt, DateTime.utc(2026, 10, 21, 10, 30));
    expect(
      data.toJson()['sessions'][0]['occurredAt'],
      '2026-10-21T10:30:00.000Z',
    );
    expect(data.toJson()['accounts'][0]['createdAt'], endsWith('Z'));
    expect(
      data.toJson()['accounts'][0]['quotaWindows'][0]['resetAt'],
      endsWith('Z'),
    );
  });

  test('IANA timezone month boundary uses exact half-open UTC interval', () {
    final t = DateTime.utc(2026, 12, 31, 17);
    final rows = [
      usage('old', t.subtract(const Duration(microseconds: 1))),
      usage('start', t),
      usage('end', DateTime.utc(2027, 1, 1, 17)),
    ];
    expect(
      UsageCalculator.filter(
        rows,
        t,
        timezone: 'Asia/Ho_Chi_Minh',
      ).map((s) => s.id),
      ['start'],
    );
    expect(ReportingCalendar.dayKey(t, 'Asia/Ho_Chi_Minh'), '01/01/2027');
    expect(ReportingCalendar.dayKey(t, 'UTC'), '31/12/2026');
  });

  test(
    'custom cycle day31 clamps independently across leap February and year',
    () {
      final before = ReportingCalendar.cycle(
        DateTime.utc(2024, 2, 28),
        'UTC',
        31,
      );
      expect(before.start, DateTime.utc(2024, 1, 31));
      expect(before.end, DateTime.utc(2024, 2, 29));
      final after = ReportingCalendar.cycle(
        DateTime.utc(2024, 2, 29),
        'UTC',
        31,
      );
      expect(after.start, DateTime.utc(2024, 2, 29));
      expect(after.end, DateTime.utc(2024, 3, 31));
      final year = ReportingCalendar.cycle(DateTime.utc(2027, 1, 1), 'UTC', 15);
      expect(year.start, DateTime.utc(2026, 12, 15));
      expect(year.end, DateTime.utc(2027, 1, 15));
    },
  );

  test('IANA day boundaries honor DST 23h/25h instead of fixed24h', () {
    final spring = ReportingCalendar.wall('America/New_York', 2026, 3, 8);
    final springEnd = ReportingCalendar.wall('America/New_York', 2026, 3, 9);
    expect(springEnd.difference(spring).inHours, 23);
    final fall = ReportingCalendar.wall('America/New_York', 2026, 11, 1);
    final fallEnd = ReportingCalendar.wall('America/New_York', 2026, 11, 2);
    expect(fallEnd.difference(fall).inHours, 25);
    final a = account(zone: 'America/New_York', day: 8);
    final rows = [
      usage('before', spring.subtract(const Duration(microseconds: 1))),
      usage('exact', spring),
      usage('tomorrow', springEnd),
    ];
    expect(
      UsageCalculator.dailyCosts(rows, spring, timezone: a.timezone).last,
      0,
    );
    expect(
      UsageCalculator.filter(
        rows,
        spring,
        timezone: a.timezone,
      ).map((s) => s.id),
      ['exact', 'before'],
    );
  });

  test('invalid zone/cycle, duplicate windows/purposes and dishonest cost/source are rejected', () {
    expect(
      () => LedgerValidation.account(account(zone: 'Made/Up')),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.account(account(day: 0)),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.account(account(day: 32)),
      throwsArgumentError,
    );
    final q = QuotaSnapshot(
      window: 'Week',
      usedPercent: 0,
      observedAt: now,
      resetAt: now.add(const Duration(days: 1)),
    );
    expect(
      () => LedgerValidation.account(account().copyWith(quotaWindows: [q, q])),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.account(
        account().copyWith(defaultPurposes: [Purpose.code, Purpose.code]),
      ),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.usage(
        UsageSession(
          id: 'x',
          accountId: 'real',
          title: 'Test',
          purpose: Purpose.code,
          occurredAt: now,
          costBasis: CostBasis.actual,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.usage(
        UsageSession(
          id: 'x',
          accountId: 'real',
          title: 'Test',
          purpose: Purpose.code,
          occurredAt: now,
          dataSource: DataSource.demo,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('quota replaces the same key, preserves other windows, stale does not reset, delete is scoped', () async {
    final repo = MemoryRepository()
      ..data = LedgerData(accounts: [account()], sessions: []);
    final c = owner(repo);
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
    final c = owner(repo);
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
    final c = owner(repo);
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

  test('demo reset/clear retain manual/legacy records even with old seed ID collisions', () async {
    final repo = MemoryRepository()
      ..data = LedgerData(
        accounts: [account(id: 'codex')],
        sessions: [usage('seed-0', now, accountId: 'codex', cost: 77)],
      );
    final c = owner(repo);
    await c.read(ledgerProvider.future);
    final vm = c.read(ledgerProvider.notifier);
    await vm.resetDemo();
    expect(repo.data!.account('codex')!.isDemo, isFalse);
    expect(repo.data!.sessions.first.costMicros, 77);
    expect(repo.data!.sessions.where((s) => s.isDemo).length, 12);
    LedgerValidation.snapshot(repo.data!);
    await vm.resetDemo();
    expect(repo.data!.sessions.length, 13);
    await vm.clearDemo();
    expect(repo.data!.sessions.single.id, 'seed-0');
    expect(repo.data!.accounts.single.id, 'codex');
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
    final c = owner(repo);
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
    final c = owner(repo);
    await c.read(ledgerProvider.future);
    expect(c.read(dashboardProjectionProvider).budget, 1000000);
    expect(c.read(dashboardProjectionProvider).spent, 7);
    c.read(dataScopeProvider.notifier).select(DataScope.legacy);
    expect(c.read(dashboardProjectionProvider).budget, 50000000);
    expect(c.read(dashboardProjectionProvider).spent, 12840000);
    repo.data = legacy.copyWith(sessions: []);
    final metadataOnly = owner(repo);
    await metadataOnly.read(ledgerProvider.future);
    expect(metadataOnly.read(effectiveDataScopeProvider), DataScope.legacy);
    expect(metadataOnly.read(dashboardProjectionProvider).budget, 50000000);
  });

  test(
    'immutable createdAt compares the instant after UTC persistence/reload',
    () async {
      final native = AIAccount(
        id: 'real',
        alias: 'Local time',
        provider: 'OpenAI',
        product: 'Codex',
        billingMode: BillingMode.api,
        plan: '',
        createdAt: now.toLocal(),
      );
      final repo = MemoryRepository()
        ..data = LedgerData.fromJson(
          LedgerData(accounts: [native], sessions: []).toJson(),
        );
      final c = owner(repo);
      await c.read(ledgerProvider.future);
      await c
          .read(ledgerProvider.notifier)
          .saveAccount(native.copyWith(alias: 'Updated'));
      expect(repo.data!.accounts.single.alias, 'Updated');
      expect(
        repo.data!.accounts.single.createdAt.isAtSameMomentAs(now),
        isTrue,
      );
    },
  );

  test('preferred metric honors known zero, uses count for unknown costs', () {
    expect(
      UsageCalculator.preferredMetric([usage('x', now, cost: null)]),
      UsageMetric.sessions,
    );
    expect(
      UsageCalculator.preferredMetric([usage('x', now, cost: 0)]),
      UsageMetric.cost,
    );
  });
}
