import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
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

  test(
    'logout stops listeners and old repository stays revoked after A returns',
    () async {
      final errors = <Object>[];
      final done = Completer<void>();
      final sub = h.repo.watchAccounts().listen(
        (_) {},
        onError: errors.add,
        onDone: done.complete,
      );
      await Future<void>.delayed(Duration.zero);
      expect(h.store.activeListeners, 1);
      h.store.signIn('B');
      await done.future;
      expect(h.store.activeListeners, 0);
      expect(errors.single, h.problem(CloudLedgerProblem.unauthenticated));
      h.store.signIn('A');
      await expectLater(
        h.create(),
        throwsA(h.problem(CloudLedgerProblem.unauthenticated)),
      );
      await sub.cancel();
    },
  );

  test('in-flight owner change never reports successful write', () async {
    h.store.beforeCommit = () => h.store.signIn('B');
    await expectLater(
      h.create(),
      throwsA(h.problem(CloudLedgerProblem.unauthenticated)),
    );
    expect(
      h.store.documents.keys.any((p) => p.startsWith('users/B/')),
      isFalse,
    );
  });

  test(
    'closed repository blocks reads/writes and releases subscriptions',
    () async {
      await h.repo.close();
      await expectLater(
        h.create(),
        throwsA(h.problem(CloudLedgerProblem.closed)),
      );
      await expectLater(
        h.repo.watchAccounts().first,
        throwsA(h.problem(CloudLedgerProblem.closed)),
      );
      expect(h.store.identity.hasListener, isFalse);
      expect(h.store.activeListeners, 0);
    },
  );

  test('cancel/error stream detaches and retry can resubscribe', () async {
    final sub = h.repo.watchAccounts().listen((_) {});
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(h.store.activeListeners, 0);
    final result = h.repo.watchAccounts().first;
    h.store.changes.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await result;
    final error = Completer<Object>();
    final live = h.repo.watchAccounts().listen((_) {}, onError: error.complete);
    await Future<void>.delayed(Duration.zero);
    h.store.changes.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    expect(await error.future, h.problem(CloudLedgerProblem.permission));
    await live.cancel();
    expect((await h.repo.watchAccounts().first).records, isEmpty);
  });

  test('a different authenticated owner has independent empty paths', () async {
    await h.create();
    h.store.signIn('B');
    final other = FirestoreLedgerRepository(
      ownerId: 'B',
      store: h.store,
      now: () => h.now,
    );
    addTearDown(other.close);
    expect((await other.watchAccounts().first).records, isEmpty);
    await other.createAccount(h.account(), operationId: 'a-create');
    expect(h.store.documents.containsKey('users/A/accounts/a'), isTrue);
    expect(h.store.documents.containsKey('users/B/accounts/a'), isTrue);
    expect((await other.watchAccounts().first).records.single.ownerId, 'B');
    await expectLater(
      h.repo.deleteAccount('a', expectedRevision: 1, operationId: 'forbidden'),
      throwsA(h.problem(CloudLedgerProblem.unauthenticated)),
    );
  });
}
