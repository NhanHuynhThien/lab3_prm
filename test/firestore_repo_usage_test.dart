import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
import 'package:token_ledger/models/ledger.dart';

import 'support/firestore_repo_harness.dart';

void main() {
  late FirestoreRepoHarness h;

  setUp(() {
    h = FirestoreRepoHarness()..init();
  });

  tearDown(() async {
    await h.dispose();
  });

  test('create retry after lost acknowledgement is exactly once', () async {
    await h.create();
    h.store.failAfterCommit = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    await expectLater(
      h.repo.createUsage(h.usage(), operationId: 'u-create'),
      throwsA(h.problem(CloudLedgerProblem.unavailable)),
    );
    expect(await h.repo.createUsage(h.usage(), operationId: 'u-create'), 1);
    expect(h.count('usageCount'), 1);
    expect(
      h.store.documents.keys
          .where((p) => p.contains('/usage_sessions/'))
          .length,
      1,
    );
  });

  test('retry create after subsequent delete cannot resurrect usage', () async {
    await h.create();
    await h.repo.createUsage(h.usage(), operationId: 'u-create');
    await h.repo.deleteUsage('u', expectedRevision: 1, operationId: 'u-delete');
    await h.repo.createUsage(h.usage(), operationId: 'u-create');
    await h.repo.deleteUsage('u', expectedRevision: 1, operationId: 'u-delete');
    expect(h.count('usageCount'), 0);
    expect(h.store.documents.containsKey('users/A/usage_sessions/u'), isFalse);
  });

  test(
    'usage edits preserve account relation and counters including zero/null',
    () async {
      await h.create();
      await h.repo.createUsage(h.usage(), operationId: 'u-create');
      final q = CloudUsageQuery(
        start: h.now.subtract(const Duration(days: 1)),
        end: h.now.add(const Duration(days: 1)),
      );
      var value = (await h.repo.watchUsage(q).first).records.single.value;
      expect(value.inputTokens, isNull);
      expect(value.costMicros, isNull);
      expect(value.effectiveCostBasis, CostBasis.unknown);
      await h.repo.updateUsage(
        h.usage(input: 0, output: 0, cost: 0),
        expectedRevision: 1,
        operationId: 'u-edit',
      );
      value = (await h.repo.watchUsage(q).first).records.single.value;
      expect(value.knownTokens, 0);
      expect(value.costMicros, 0);
      expect(h.count('usageCount'), 1);
      await h.repo.createAccount(h.account('b'), operationId: 'b-create');
      await expectLater(
        h.repo.updateUsage(
          h.usage(accountId: 'b'),
          expectedRevision: 2,
          operationId: 'u-move',
        ),
        throwsA(h.problem(CloudLedgerProblem.conflict)),
      );
      expect(h.count('usageCount'), 1);
    },
  );

  test('archive blocks new usage but permits historical edit/delete', () async {
    await h.create();
    await h.repo.createUsage(h.usage(), operationId: 'u-create');
    await h.repo.updateAccount(
      h.account().copyWith(archived: true),
      expectedRevision: 2,
      operationId: 'a-archive',
    );
    await expectLater(
      h.repo.createUsage(h.usage(id: 'v'), operationId: 'v-create'),
      throwsA(h.problem(CloudLedgerProblem.conflict)),
    );
    await h.repo.updateUsage(
      h.usage(cost: 7),
      expectedRevision: 1,
      operationId: 'u-edit',
    );
    await h.repo.deleteUsage('u', expectedRevision: 2, operationId: 'u-delete');
    expect(h.count('usageCount'), 0);
  });

  test('missing/foreign account cannot create a usage or receipt', () async {
    await expectLater(
      h.repo.createUsage(h.usage(accountId: 'absent'), operationId: 'u-create'),
      throwsA(h.problem(CloudLedgerProblem.notFound)),
    );
    expect(h.store.documents, isEmpty);
  });

  test(
    'delete account with usage or quota fails without partial writes',
    () async {
      await h.create();
      await h.repo.createUsage(h.usage(), operationId: 'u-create');
      await expectLater(
        h.repo.deleteAccount('a', expectedRevision: 2, operationId: 'a-delete'),
        throwsA(h.problem(CloudLedgerProblem.conflict)),
      );
      await h.repo.deleteUsage(
        'u',
        expectedRevision: 1,
        operationId: 'u-delete',
      );
      await h.repo.createQuota(h.quota(), operationId: 'q-create');
      await expectLater(
        h.repo.deleteAccount(
          'a',
          expectedRevision: 4,
          operationId: 'a-delete2',
        ),
        throwsA(h.problem(CloudLedgerProblem.conflict)),
      );
      await h.repo.deleteQuota(
        'a',
        'weekly',
        expectedRevision: 1,
        operationId: 'q-delete',
      );
      await h.repo.deleteAccount(
        'a',
        expectedRevision: 5,
        operationId: 'a-delete3',
      );
      expect(h.store.documents.containsKey('users/A/accounts/a'), isFalse);
    },
  );

  test('concurrent usage create vs account delete has no orphan', () async {
    await h.create();
    final results = await Future.wait([
      h.repo
          .createUsage(h.usage(), operationId: 'u-create')
          .then<Object>((v) => v, onError: (Object e) => e),
      h.repo
          .deleteAccount('a', expectedRevision: 1, operationId: 'a-delete')
          .then<Object>((_) => 'deleted', onError: (Object e) => e),
    ]);
    expect(results.whereType<CloudLedgerFailure>().length, 1);
    final existsUsage = h.store.documents.containsKey(
      'users/A/usage_sessions/u',
    );
    final existsAccount = h.store.documents.containsKey('users/A/accounts/a');
    expect(existsUsage && !existsAccount, isFalse);
    if (existsUsage) expect(h.count('usageCount'), 1);
    expect(h.store.transactionAttempts, greaterThan(3));
  });

  test(
    'two concurrent creates with same operation ID increment once',
    () async {
      await h.create();
      expect(
        await Future.wait([
          h.repo.createUsage(h.usage(), operationId: 'same'),
          h.repo.createUsage(h.usage(), operationId: 'same'),
        ]),
        [1, 1],
      );
      expect(h.count('usageCount'), 1);
    },
  );

  test(
    'invalid token pair, amount, future date and expired quota write nothing',
    () async {
      await h.create();
      for (final value in [
        h.usage(input: 1),
        h.usage(cost: -1),
        h.usage(at: h.now.add(const Duration(seconds: 1))),
      ]) {
        await expectLater(
          h.repo.createUsage(value, operationId: 'invalid'),
          throwsA(h.problem(CloudLedgerProblem.invalidData)),
        );
      }
      await expectLater(
        h.repo.createQuota(h.quota(reset: h.now), operationId: 'q-invalid'),
        throwsA(h.problem(CloudLedgerProblem.invalidData)),
      );
      expect(h.count('usageCount'), 0);
      expect(h.count('quotaCount'), 0);
    },
  );

  test('interval and filters use full scoped dataset [start,end)', () async {
    await h.create();
    await h.repo.createUsage(
      h.usage(id: 'before', at: h.now.subtract(const Duration(days: 2))),
      operationId: 'before',
    );
    await h.repo.createUsage(
      h.usage(id: 'start', at: h.now.subtract(const Duration(days: 1))),
      operationId: 'start',
    );
    await h.repo.createUsage(
      h.usage(id: 'end', at: h.now),
      operationId: 'end',
    );
    final snapshot = await h.repo
        .watchUsage(
          CloudUsageQuery(
            start: h.now.subtract(const Duration(days: 1)),
            end: h.now,
            accountId: 'a',
            purpose: Purpose.code,
          ),
        )
        .first;
    expect(snapshot.records.map((r) => r.id), ['start']);
    expect(h.store.lastCollection, 'users/A/usage_sessions');
    expect(h.store.lastFilters.length, 4);
    expect(h.store.lastOrder, 'payload.occurredAt');
  });

  test(
    'usage counter relation markers match exactly the created/deleted ID',
    () async {
      await h.create();
      await h.repo.createUsage(h.usage(), operationId: 'u-create');
      expect(
        h.store.documents['users/A/accounts/a']!['lastUsageMutationId'],
        'u',
      );
      await h.repo.deleteUsage(
        'u',
        expectedRevision: 1,
        operationId: 'u-delete',
      );
      expect(
        h.store.documents['users/A/accounts/a']!['lastUsageMutationId'],
        'u',
      );
      expect(h.count('usageCount'), 0);
      await expectLater(
        h.repo.deleteUsage(
          'u',
          expectedRevision: 1,
          operationId: 'other-delete',
        ),
        throwsA(h.problem(CloudLedgerProblem.notFound)),
      );
      expect(h.count('usageCount'), 0);
    },
  );
}
