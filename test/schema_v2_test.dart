import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/ledger_repository.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;
import 'support/faulty_preferences.dart';
import 'support/schema_v2_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 21, 10);
  const key = LocalLedgerRepository.storageKey;
  const backup = LocalLedgerRepository.migrationBackupKey;

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
      final c = createSchemaTestOwner(repo, now);
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
}
