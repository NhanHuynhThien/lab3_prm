import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';

import 'ledger_cloud_fake.dart';

class FirestoreRepoHarness {
  final DateTime now = DateTime.utc(2026, 10, 21, 9);
  late LedgerCloudFake store;
  late FirestoreLedgerRepository repo;

  AIAccount account([String id = 'a']) => AIAccount(
    id: id,
    alias: 'Claude',
    provider: 'Anthropic',
    product: 'Claude',
    billingMode: BillingMode.subscription,
    plan: '',
    createdAt: now,
    budgetMicros: 1234567,
  );

  UsageSession usage({
    String id = 'u',
    String accountId = 'a',
    int? cost,
    int? input,
    int? output,
    DateTime? at,
  }) => UsageSession(
    id: id,
    accountId: accountId,
    title: 'Lập trình',
    purpose: Purpose.code,
    occurredAt: at ?? now,
    inputTokens: input,
    outputTokens: output,
    costMicros: cost,
  );

  AccountQuota quota({
    String key = 'weekly',
    String label = 'Tuần',
    DateTime? reset,
    int percent = 50,
  }) => AccountQuota(
    accountId: 'a',
    snapshot: QuotaSnapshot(
      windowKey: key,
      window: label,
      usedPercent: percent,
      observedAt: now,
      resetAt: reset ?? now.add(const Duration(days: 7)),
    ),
  );

  Matcher problem(CloudLedgerProblem p) =>
      isA<CloudLedgerFailure>().having((e) => e.problem, 'problem', p);

  Future<void> create() =>
      repo.createAccount(account(), operationId: 'a-create');

  int count(String field) =>
      store.documents['users/A/accounts/a']![field] as int;

  void init() {
    store = LedgerCloudFake();
    repo = FirestoreLedgerRepository(
      ownerId: 'A',
      store: store,
      now: () => now,
    );
  }

  Future<void> dispose() async {
    await repo.close();
    await store.close();
  }
}
