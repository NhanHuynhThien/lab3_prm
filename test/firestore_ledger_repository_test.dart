import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';

import 'support/firestore_repo_harness.dart';

void main() {
  late FirestoreRepoHarness h;

  setUp(() {
    h = FirestoreRepoHarness()..init();
  });

  tearDown(() async {
    await h.dispose();
  });

  test('new cloud owner is empty; no local seed/profile writes', () async {
    final snapshot = await h.repo.watchAccounts().first;
    expect(snapshot.records, isEmpty);
    expect(h.store.documents, isEmpty);
    expect(snapshot.serverConfirmed, isTrue);
  });

  test(
    'account converter preserves micros/nulls/source/timezone and UTC',
    () async {
      await h.create();
      final data = (await h.repo.watchAccounts().first).records.single;
      expect(data.value.budgetMicros, 1234567);
      expect(data.value.defaultModelId, isNull);
      expect(data.value.quotaWindows, isEmpty);
      expect(data.value.createdAt, h.now);
      expect(data.revision, 1);
      expect(data.usageCount, 0);
      expect(data.createdAt!.isUtc, isTrue);
      expect(
        h.store.documents.keys.every((p) => p.startsWith('users/A/')),
        isTrue,
      );
    },
  );

  test('account edit uses revision; createdAt/source are immutable', () async {
    await h.create();
    expect(
      await h.repo.updateAccount(
        h.account().copyWith(alias: 'Mới'),
        expectedRevision: 1,
        operationId: 'a-edit',
      ),
      2,
    );
    await expectLater(
      h.repo.updateAccount(
        h.account().copyWith(alias: 'Cũ'),
        expectedRevision: 1,
        operationId: 'a-stale',
      ),
      throwsA(h.problem(CloudLedgerProblem.conflict)),
    );
    expect(
      (await h.repo.watchAccounts().first).records.single.value.alias,
      'Mới',
    );
  });

  test('operation ID reuse for a different command is rejected', () async {
    await h.create();
    await expectLater(
      h.repo.createAccount(h.account('b'), operationId: 'a-create'),
      throwsA(h.problem(CloudLedgerProblem.conflict)),
    );
    expect(h.store.documents.containsKey('users/A/accounts/b'), isFalse);
  });

  test('concurrent stale account edits do not silently overwrite', () async {
    await h.create();
    final results = await Future.wait(
      ['X', 'Y'].map(
        (alias) => h.repo
            .updateAccount(
              h.account().copyWith(alias: alias),
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

  test(
    'permission/network failures are typed and redact raw SDK messages',
    () async {
      for (final code in [
        'permission-denied',
        'unavailable',
        'unauthenticated',
      ]) {
        h.store.failNext = FirebaseException(
          plugin: 'cloud_firestore',
          code: code,
          message: 'private token email@example.test',
        );
        await expectLater(
          h.create(),
          throwsA(
            isA<CloudLedgerFailure>().having(
              (e) => e.message,
              'redacted',
              isNot(contains('private')),
            ),
          ),
        );
        expect(h.store.documents, isEmpty);
      }
    },
  );

  test('owner path rejects traversal; foreign envelope is rejected', () async {
    expect(
      () => FirestoreLedgerRepository(ownerId: '../B', store: h.store),
      throwsArgumentError,
    );
    await h.create();
    h.store.documents['users/A/accounts/a']!['ownerId'] = 'B';
    await expectLater(
      h.repo.watchAccounts().first,
      throwsA(h.problem(CloudLedgerProblem.invalidData)),
    );
  });

  test(
    'malformed schema, unexpected fields or document ID mismatch fail closed',
    () async {
      await h.create();
      final original = h.store.copy(h.store.documents['users/A/accounts/a'])!;
      for (final patch in [
        {'schemaVersion': 9},
        {'extra': 'secret'},
        {
          'payload': {...original['payload'] as Map, 'id': 'other'},
        },
      ]) {
        h.store.documents['users/A/accounts/a'] = {...original, ...patch};
        await expectLater(
          h.repo.watchAccounts().first,
          throwsA(h.problem(CloudLedgerProblem.invalidData)),
        );
      }
    },
  );

  test('cache and pending metadata never become server-confirmed', () async {
    await h.create();
    h.store.fromCache = true;
    var snapshot = await h.repo.watchAccounts().first;
    expect(snapshot.fromCache, isTrue);
    expect(snapshot.serverConfirmed, isFalse);
    h.store.fromCache = false;
    h.store.pending = true;
    h.store.documents['users/A/accounts/a']!['updatedAt'] = null;
    snapshot = await h.repo.watchAccounts().first;
    expect(snapshot.hasPendingWrites, isTrue);
    expect(snapshot.serverConfirmed, isFalse);
    expect(snapshot.records.single.updatedAt, isNull);
  });

  test('account active filter uses archived field and server order', () async {
    await h.create();
    await h.repo.updateAccount(
      h.account().copyWith(archived: true),
      expectedRevision: 1,
      operationId: 'archive',
    );
    expect(
      (await h.repo.watchAccounts(archived: false).first).records,
      isEmpty,
    );
    expect(
      (await h.repo.watchAccounts(archived: true).first).records.length,
      1,
    );
    expect(h.store.lastOrder, 'updatedAt');
  });

  test(
    'invalid counters, noninteger schema and currency fail closed',
    () async {
      await h.create();
      final original = h.store.copy(h.store.documents['users/A/accounts/a'])!;
      for (final patch in [
        {'usageCount': -1},
        {'usageCount': 0.5},
        {'schemaVersion': 1.0},
        {
          'payload': {...original['payload'] as Map, 'currency': 'VND'},
        },
      ]) {
        h.store.documents['users/A/accounts/a'] = {...original, ...patch};
        await expectLater(
          h.repo.watchAccounts().first,
          throwsA(h.problem(CloudLedgerProblem.invalidData)),
        );
      }
    },
  );

  test(
    'account edit cannot replace source with demo or change business createdAt',
    () async {
      await h.create();
      await expectLater(
        h.repo.updateAccount(
          h.account().copyWith(isDemo: true, dataSource: DataSource.demo),
          expectedRevision: 1,
          operationId: 'demo-switch',
        ),
        throwsA(h.problem(CloudLedgerProblem.conflict)),
      );
      final replacement = AIAccount(
        id: 'a',
        alias: 'Claude',
        provider: 'Anthropic',
        product: 'Claude',
        billingMode: BillingMode.subscription,
        plan: '',
        createdAt: h.now.subtract(const Duration(days: 1)),
      );
      await expectLater(
        h.repo.updateAccount(
          replacement,
          expectedRevision: 1,
          operationId: 'date-switch',
        ),
        throwsA(h.problem(CloudLedgerProblem.conflict)),
      );
    },
  );

  test(
    'new cloud account does not accept a nested local quota snapshot',
    () async {
      await expectLater(
        h.repo.createAccount(
          h.account().copyWith(quotaWindows: [h.quota().snapshot]),
          operationId: 'bad-account',
        ),
        throwsA(h.problem(CloudLedgerProblem.invalidData)),
      );
      expect(h.store.documents, isEmpty);
    },
  );
}
