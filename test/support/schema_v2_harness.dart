import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/services/ledger_repository.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import '../ledger_viewmodel_test.dart' show MemoryRepository;
import 'faulty_preferences.dart';

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

AIAccount createSchemaTestAccount(
  DateTime now, {
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

UsageSession createSchemaTestUsage(
  DateTime date,
  String id, {
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

ProviderContainer createSchemaTestOwner(
  MemoryRepository repository,
  DateTime now,
) {
  final c = ProviderContainer(
    overrides: [
      ledgerRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => now),
    ],
  );
  addTearDown(c.dispose);
  return c;
}
