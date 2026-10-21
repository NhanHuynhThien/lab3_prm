import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/firestore_ledger_codec.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';

import 'support/ledger_cloud_fake.dart';

void main() {
  final now = DateTime.utc(2026, 10, 21, 9);
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
  setUp(() {
    store = LedgerCloudFake();
    repo = FirestoreLedgerRepository(
      ownerId: 'A',
      store: store,
      now: () => now,
    );
  });
  tearDown(() async {
    await repo.close();
    await store.close();
  });

  test('new cloud owner is empty; no local seed/profile writes', () async {
    final snapshot = await repo.watchAccounts().first;
    expect(snapshot.records, isEmpty);
    expect(store.documents, isEmpty);
    expect(snapshot.serverConfirmed, isTrue);
  });
  test(
    'account converter preserves micros/nulls/source/timezone and UTC',
    () async {
      await create();
      final data = (await repo.watchAccounts().first).records.single;
      expect(data.value.budgetMicros, 1234567);
      expect(data.value.defaultModelId, isNull);
      expect(data.value.quotaWindows, isEmpty);
      expect(data.value.createdAt, now);
      expect(data.revision, 1);
      expect(data.usageCount, 0);
      expect(data.createdAt!.isUtc, isTrue);
      expect(
        store.documents.keys.every((p) => p.startsWith('users/A/')),
        isTrue,
      );
    },
  );
  test('account edit uses revision; createdAt/source are immutable', () async {
    await create();
    expect(
      await repo.updateAccount(
        account().copyWith(alias: 'Mới'),
        expectedRevision: 1,
        operationId: 'a-edit',
      ),
      2,
    );
    await expectLater(
      repo.updateAccount(
        account().copyWith(alias: 'Cũ'),
        expectedRevision: 1,
        operationId: 'a-stale',
      ),
      throwsA(problem(CloudLedgerProblem.conflict)),
    );
    expect(
      (await repo.watchAccounts().first).records.single.value.alias,
      'Mới',
    );
  });
  test('create retry after lost acknowledgement is exactly once', () async {
    await create();
    store.failAfterCommit = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    await expectLater(
      repo.createUsage(usage(), operationId: 'u-create'),
      throwsA(problem(CloudLedgerProblem.unavailable)),
    );
    expect(await repo.createUsage(usage(), operationId: 'u-create'), 1);
    expect(count('usageCount'), 1);
    expect(
      store.documents.keys.where((p) => p.contains('/usage_sessions/')).length,
      1,
    );
  });
  test('operation ID reuse for a different command is rejected', () async {
    await create();
    await expectLater(
      repo.createAccount(account('b'), operationId: 'a-create'),
      throwsA(problem(CloudLedgerProblem.conflict)),
    );
    expect(store.documents.containsKey('users/A/accounts/b'), isFalse);
  });
  test('retry create after subsequent delete cannot resurrect usage', () async {
    await create();
    await repo.createUsage(usage(), operationId: 'u-create');
    await repo.deleteUsage('u', expectedRevision: 1, operationId: 'u-delete');
    await repo.createUsage(usage(), operationId: 'u-create');
    await repo.deleteUsage('u', expectedRevision: 1, operationId: 'u-delete');
    expect(count('usageCount'), 0);
    expect(store.documents.containsKey('users/A/usage_sessions/u'), isFalse);
  });
  test(
    'usage edits preserve account relation and counters including zero/null',
    () async {
      await create();
      await repo.createUsage(usage(), operationId: 'u-create');
      final q = CloudUsageQuery(
        start: now.subtract(const Duration(days: 1)),
        end: now.add(const Duration(days: 1)),
      );
      var value = (await repo.watchUsage(q).first).records.single.value;
      expect(value.inputTokens, isNull);
      expect(value.costMicros, isNull);
      expect(value.effectiveCostBasis, CostBasis.unknown);
      await repo.updateUsage(
        usage(input: 0, output: 0, cost: 0),
        expectedRevision: 1,
        operationId: 'u-edit',
      );
      value = (await repo.watchUsage(q).first).records.single.value;
      expect(value.knownTokens, 0);
      expect(value.costMicros, 0);
      expect(count('usageCount'), 1);
      await repo.createAccount(account('b'), operationId: 'b-create');
      await expectLater(
        repo.updateUsage(
          usage(accountId: 'b'),
          expectedRevision: 2,
          operationId: 'u-move',
        ),
        throwsA(problem(CloudLedgerProblem.conflict)),
      );
      expect(count('usageCount'), 1);
    },
  );
  test('archive blocks new usage but permits historical edit/delete', () async {
    await create();
    await repo.createUsage(usage(), operationId: 'u-create');
    await repo.updateAccount(
      account().copyWith(archived: true),
      expectedRevision: 2,
      operationId: 'a-archive',
    );
    await expectLater(
      repo.createUsage(usage(id: 'v'), operationId: 'v-create'),
      throwsA(problem(CloudLedgerProblem.conflict)),
    );
    await repo.updateUsage(
      usage(cost: 7),
      expectedRevision: 1,
      operationId: 'u-edit',
    );
    await repo.deleteUsage('u', expectedRevision: 2, operationId: 'u-delete');
    expect(count('usageCount'), 0);
  });
  test('missing/foreign account cannot create a usage or receipt', () async {
    await expectLater(
      repo.createUsage(usage(accountId: 'absent'), operationId: 'u-create'),
      throwsA(problem(CloudLedgerProblem.notFound)),
    );
    expect(store.documents, isEmpty);
  });
  test(
    'delete account with usage or quota fails without partial writes',
    () async {
      await create();
      await repo.createUsage(usage(), operationId: 'u-create');
      await expectLater(
        repo.deleteAccount('a', expectedRevision: 2, operationId: 'a-delete'),
        throwsA(problem(CloudLedgerProblem.conflict)),
      );
      await repo.deleteUsage('u', expectedRevision: 1, operationId: 'u-delete');
      await repo.createQuota(quota(), operationId: 'q-create');
      await expectLater(
        repo.deleteAccount('a', expectedRevision: 4, operationId: 'a-delete2'),
        throwsA(problem(CloudLedgerProblem.conflict)),
      );
      await repo.deleteQuota(
        'a',
        'weekly',
        expectedRevision: 1,
        operationId: 'q-delete',
      );
      await repo.deleteAccount(
        'a',
        expectedRevision: 5,
        operationId: 'a-delete3',
      );
      expect(store.documents.containsKey('users/A/accounts/a'), isFalse);
    },
  );
  test('concurrent usage create vs account delete has no orphan', () async {
    await create();
    final results = await Future.wait([
      repo
          .createUsage(usage(), operationId: 'u-create')
          .then<Object>((v) => v, onError: (Object e) => e),
      repo
          .deleteAccount('a', expectedRevision: 1, operationId: 'a-delete')
          .then<Object>((_) => 'deleted', onError: (Object e) => e),
    ]);
    expect(results.whereType<CloudLedgerFailure>().length, 1);
    final existsUsage = store.documents.containsKey('users/A/usage_sessions/u');
    final existsAccount = store.documents.containsKey('users/A/accounts/a');
    expect(existsUsage && !existsAccount, isFalse);
    if (existsUsage) expect(count('usageCount'), 1);
    expect(store.transactionAttempts, greaterThan(3));
  });
  test(
    'two concurrent creates with same operation ID increment once',
    () async {
      await create();
      expect(
        await Future.wait([
          repo.createUsage(usage(), operationId: 'same'),
          repo.createUsage(usage(), operationId: 'same'),
        ]),
        [1, 1],
      );
      expect(count('usageCount'), 1);
    },
  );
  test('concurrent stale account edits do not silently overwrite', () async {
    await create();
    final results = await Future.wait(
      ['X', 'Y'].map(
        (alias) => repo
            .updateAccount(
              account().copyWith(alias: alias),
              expectedRevision: 1,
              operationId: alias,
            )
            .then<Object>((v) => v, onError: (Object e) => e),
      ),
    );
    expect(results.whereType<int>(), [2]);
    expect(
      results.whereType<CloudLedgerFailure>().single.problem,
      CloudLedgerProblem.conflict,
    );
  });
  test('quota key uniqueness, label reservation, rename and delete', () async {
    await create();
    await repo.createQuota(quota(), operationId: 'q-create');
    await expectLater(
      repo.createQuota(
        quota(key: 'other', label: ' TUẦN '),
        operationId: 'q-duplicate-label',
      ),
      throwsA(problem(CloudLedgerProblem.conflict)),
    );
    await expectLater(
      repo.createQuota(quota(), operationId: 'q-duplicate-key'),
      throwsA(problem(CloudLedgerProblem.conflict)),
    );
    await repo.updateQuota(
      quota(label: 'Bảy ngày'),
      expectedRevision: 1,
      operationId: 'q-edit',
    );
    final record = (await repo.watchQuotas('a').first).records.single;
    expect(record.value.snapshot.windowKey, 'weekly');
    expect(record.value.snapshot.window, 'Bảy ngày');
    expect(count('quotaCount'), 1);
    await repo.deleteQuota(
      'a',
      'weekly',
      expectedRevision: 2,
      operationId: 'q-delete',
    );
    expect(count('quotaCount'), 0);
    expect(
      store.documents.keys.any((p) => p.contains('/quota_labels/')),
      isFalse,
    );
    await expectLater(
      repo.updateQuota(quota(), expectedRevision: 2, operationId: 'q-stale'),
      throwsA(problem(CloudLedgerProblem.notFound)),
    );
  });
  test(
    'stale quota retains observation and allows metadata edit only',
    () async {
      await create();
      await repo.createQuota(quota(), operationId: 'q-create');
      final later = FirestoreLedgerRepository(
        ownerId: 'A',
        store: store,
        now: () => now.add(const Duration(days: 8)),
      );
      addTearDown(later.close);
      await later.updateQuota(
        quota(label: 'Cũ'),
        expectedRevision: 1,
        operationId: 'q-label',
      );
      await expectLater(
        later.updateQuota(
          quota(label: 'Cũ', percent: 20),
          expectedRevision: 2,
          operationId: 'q-invalid',
        ),
        throwsA(problem(CloudLedgerProblem.invalidData)),
      );
      final value =
          (await later.watchQuotas('a').first).records.single.value.snapshot;
      expect(value.isStale(now.add(const Duration(days: 8))), isTrue);
      expect(value.usedPercent, 50);
    },
  );
  test(
    'invalid token pair, amount, future date and expired quota write nothing',
    () async {
      await create();
      for (final value in [
        usage(input: 1),
        usage(cost: -1),
        usage(at: now.add(const Duration(seconds: 1))),
      ]) {
        await expectLater(
          repo.createUsage(value, operationId: 'invalid'),
          throwsA(problem(CloudLedgerProblem.invalidData)),
        );
      }
      await expectLater(
        repo.createQuota(quota(reset: now), operationId: 'q-invalid'),
        throwsA(problem(CloudLedgerProblem.invalidData)),
      );
      expect(count('usageCount'), 0);
      expect(count('quotaCount'), 0);
    },
  );
  test(
    'permission/network failures are typed and redact raw SDK messages',
    () async {
      for (final code in [
        'permission-denied',
        'unavailable',
        'unauthenticated',
      ]) {
        store.failNext = FirebaseException(
          plugin: 'cloud_firestore',
          code: code,
          message: 'private token email@example.test',
        );
        await expectLater(
          create(),
          throwsA(
            isA<CloudLedgerFailure>().having(
              (e) => e.message,
              'redacted',
              isNot(contains('private')),
            ),
          ),
        );
        expect(store.documents, isEmpty);
      }
    },
  );
  test('owner path rejects traversal; foreign envelope is rejected', () async {
    expect(
      () => FirestoreLedgerRepository(ownerId: '../B', store: store),
      throwsArgumentError,
    );
    await create();
    store.documents['users/A/accounts/a']!['ownerId'] = 'B';
    await expectLater(
      repo.watchAccounts().first,
      throwsA(problem(CloudLedgerProblem.invalidData)),
    );
  });
  test(
    'malformed schema, unexpected fields or document ID mismatch fail closed',
    () async {
      await create();
      final original = store.copy(store.documents['users/A/accounts/a'])!;
      for (final patch in [
        {'schemaVersion': 9},
        {'extra': 'secret'},
        {
          'payload': {...original['payload'] as Map, 'id': 'other'},
        },
      ]) {
        store.documents['users/A/accounts/a'] = {...original, ...patch};
        await expectLater(
          repo.watchAccounts().first,
          throwsA(problem(CloudLedgerProblem.invalidData)),
        );
      }
    },
  );
  test('cache and pending metadata never become server-confirmed', () async {
    await create();
    store.fromCache = true;
    var snapshot = await repo.watchAccounts().first;
    expect(snapshot.fromCache, isTrue);
    expect(snapshot.serverConfirmed, isFalse);
    store.fromCache = false;
    store.pending = true;
    store.documents['users/A/accounts/a']!['updatedAt'] = null;
    snapshot = await repo.watchAccounts().first;
    expect(snapshot.hasPendingWrites, isTrue);
    expect(snapshot.serverConfirmed, isFalse);
    expect(snapshot.records.single.updatedAt, isNull);
  });
  test('interval and filters use full scoped dataset [start,end)', () async {
    await create();
    await repo.createUsage(
      usage(id: 'before', at: now.subtract(const Duration(days: 2))),
      operationId: 'before',
    );
    await repo.createUsage(
      usage(id: 'start', at: now.subtract(const Duration(days: 1))),
      operationId: 'start',
    );
    await repo.createUsage(
      usage(id: 'end', at: now),
      operationId: 'end',
    );
    final snapshot = await repo
        .watchUsage(
          CloudUsageQuery(
            start: now.subtract(const Duration(days: 1)),
            end: now,
            accountId: 'a',
            purpose: Purpose.code,
          ),
        )
        .first;
    expect(snapshot.records.map((r) => r.id), ['start']);
    expect(store.lastCollection, 'users/A/usage_sessions');
    expect(store.lastFilters.length, 4);
    expect(store.lastOrder, 'payload.occurredAt');
  });
  test('account active filter uses archived field and server order', () async {
    await create();
    await repo.updateAccount(
      account().copyWith(archived: true),
      expectedRevision: 1,
      operationId: 'archive',
    );
    expect((await repo.watchAccounts(archived: false).first).records, isEmpty);
    expect((await repo.watchAccounts(archived: true).first).records.length, 1);
    expect(store.lastOrder, 'updatedAt');
  });
  test(
    'logout stops listeners and old repository stays revoked after A returns',
    () async {
      final errors = <Object>[];
      final done = Completer<void>();
      final sub = repo.watchAccounts().listen(
        (_) {},
        onError: errors.add,
        onDone: done.complete,
      );
      await Future<void>.delayed(Duration.zero);
      expect(store.activeListeners, 1);
      store.signIn('B');
      await done.future;
      expect(store.activeListeners, 0);
      expect(errors.single, problem(CloudLedgerProblem.unauthenticated));
      store.signIn('A');
      await expectLater(
        create(),
        throwsA(problem(CloudLedgerProblem.unauthenticated)),
      );
      await sub.cancel();
    },
  );
  test('in-flight owner change never reports successful write', () async {
    store.beforeCommit = () => store.signIn('B');
    await expectLater(
      create(),
      throwsA(problem(CloudLedgerProblem.unauthenticated)),
    );
    // A late server acknowledgement may exist under A, never under B.
    expect(store.documents.keys.any((p) => p.startsWith('users/B/')), isFalse);
  });
  test(
    'closed repository blocks reads/writes and releases subscriptions',
    () async {
      await repo.close();
      await expectLater(create(), throwsA(problem(CloudLedgerProblem.closed)));
      await expectLater(
        repo.watchAccounts().first,
        throwsA(problem(CloudLedgerProblem.closed)),
      );
      expect(store.identity.hasListener, isFalse);
      expect(store.activeListeners, 0);
    },
  );
  test('cancel/error stream detaches and retry can resubscribe', () async {
    final sub = repo.watchAccounts().listen((_) {});
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(store.activeListeners, 0);
    final result = repo.watchAccounts().first;
    store.changes.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    // Initial empty event can precede an injected listen error, so test on a live subscription below.
    await result;
    final error = Completer<Object>();
    final live = repo.watchAccounts().listen((_) {}, onError: error.complete);
    await Future<void>.delayed(Duration.zero);
    store.changes.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    expect(await error.future, problem(CloudLedgerProblem.permission));
    await live.cancel();
    expect((await repo.watchAccounts().first).records, isEmpty);
  });
  test(
    'quota IDs distinguish account/key delimiters and support long Unicode',
    () {
      expect(
        FirestoreLedgerCodec.quotaId('a', 'b/c'),
        isNot(FirestoreLedgerCodec.quotaId('a', 'b-c')),
      );
      expect(
        FirestoreLedgerCodec.quotaId('a', 'ạ' * 128),
        isNot(contains('/')),
      );
    },
  );

  test('a different authenticated owner has independent empty paths', () async {
    await create();
    store.signIn('B');
    final other = FirestoreLedgerRepository(
      ownerId: 'B',
      store: store,
      now: () => now,
    );
    addTearDown(other.close);
    expect((await other.watchAccounts().first).records, isEmpty);
    await other.createAccount(account(), operationId: 'a-create');
    expect(store.documents.containsKey('users/A/accounts/a'), isTrue);
    expect(store.documents.containsKey('users/B/accounts/a'), isTrue);
    expect((await other.watchAccounts().first).records.single.ownerId, 'B');
    await expectLater(
      repo.deleteAccount('a', expectedRevision: 1, operationId: 'forbidden'),
      throwsA(problem(CloudLedgerProblem.unauthenticated)),
    );
  });
  test(
    'quota retry after reset confirms receipt without changing snapshot',
    () async {
      await create();
      await repo.createQuota(quota(), operationId: 'q-create');
      final later = FirestoreLedgerRepository(
        ownerId: 'A',
        store: store,
        now: () => now.add(const Duration(days: 8)),
      );
      addTearDown(later.close);
      expect(await later.createQuota(quota(), operationId: 'q-create'), 1);
      expect(count('quotaCount'), 1);
    },
  );
  test(
    'concurrent quota create vs delete account has no orphan labels/windows',
    () async {
      await create();
      final results = await Future.wait([
        repo
            .createQuota(quota(), operationId: 'q-create')
            .then<Object>((v) => v, onError: (Object e) => e),
        repo
            .deleteAccount('a', expectedRevision: 1, operationId: 'a-delete')
            .then<Object>((_) => 'deleted', onError: (Object e) => e),
      ]);
      expect(results.whereType<CloudLedgerFailure>().length, 1);
      final hasQuota = store.documents.keys.any(
        (p) => p.contains('/quota_windows/'),
      );
      expect(
        hasQuota && !store.documents.containsKey('users/A/accounts/a'),
        isFalse,
      );
      if (hasQuota) expect(count('quotaCount'), 1);
    },
  );
  test(
    'usage counter relation markers match exactly the created/deleted ID',
    () async {
      await create();
      await repo.createUsage(usage(), operationId: 'u-create');
      expect(
        store.documents['users/A/accounts/a']!['lastUsageMutationId'],
        'u',
      );
      await repo.deleteUsage('u', expectedRevision: 1, operationId: 'u-delete');
      expect(
        store.documents['users/A/accounts/a']!['lastUsageMutationId'],
        'u',
      );
      expect(count('usageCount'), 0);
      await expectLater(
        repo.deleteUsage('u', expectedRevision: 1, operationId: 'other-delete'),
        throwsA(problem(CloudLedgerProblem.notFound)),
      );
      expect(count('usageCount'), 0);
    },
  );
  test(
    'invalid counters, noninteger schema and currency fail closed',
    () async {
      await create();
      final original = store.copy(store.documents['users/A/accounts/a'])!;
      for (final patch in [
        {'usageCount': -1},
        {'usageCount': 0.5},
        {'schemaVersion': 1.0},
        {
          'payload': {...original['payload'] as Map, 'currency': 'VND'},
        },
      ]) {
        store.documents['users/A/accounts/a'] = {...original, ...patch};
        await expectLater(
          repo.watchAccounts().first,
          throwsA(problem(CloudLedgerProblem.invalidData)),
        );
      }
    },
  );
  test(
    'account edit cannot replace source with demo or change business createdAt',
    () async {
      await create();
      await expectLater(
        repo.updateAccount(
          account().copyWith(isDemo: true, dataSource: DataSource.demo),
          expectedRevision: 1,
          operationId: 'demo-switch',
        ),
        throwsA(problem(CloudLedgerProblem.conflict)),
      );
      final replacement = AIAccount(
        id: 'a',
        alias: 'Claude',
        provider: 'Anthropic',
        product: 'Claude',
        billingMode: BillingMode.subscription,
        plan: '',
        createdAt: now.subtract(const Duration(days: 1)),
      );
      await expectLater(
        repo.updateAccount(
          replacement,
          expectedRevision: 1,
          operationId: 'date-switch',
        ),
        throwsA(problem(CloudLedgerProblem.conflict)),
      );
    },
  );
  test(
    'new cloud account does not accept a nested local quota snapshot',
    () async {
      await expectLater(
        repo.createAccount(
          account().copyWith(quotaWindows: [quota().snapshot]),
          operationId: 'bad-account',
        ),
        throwsA(problem(CloudLedgerProblem.invalidData)),
      );
      expect(store.documents, isEmpty);
    },
  );
  test('expired quota is stale and not reset to zero on read', () async {
    await create();
    await repo.createQuota(quota(percent: 88), operationId: 'q-create');
    final record = (await repo.watchQuotas('a').first).records.single;
    expect(record.value.snapshot.usedPercent, 88);
    expect(
      record.value.snapshot.isStale(now.add(const Duration(days: 8))),
      isTrue,
    );
    expect(record.value.snapshot.remainingPercent, 12);
  });
}
