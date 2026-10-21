import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
import 'package:token_ledger/services/firestore_ledger_codec.dart';
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

  test('quota key uniqueness, label reservation, rename and delete', () async {
    await h.create();
    await h.repo.createQuota(h.quota(), operationId: 'q-create');
    await expectLater(
      h.repo.createQuota(
        h.quota(key: 'other', label: ' TUẦN '),
        operationId: 'q-duplicate-label',
      ),
      throwsA(h.problem(CloudLedgerProblem.conflict)),
    );
    await expectLater(
      h.repo.createQuota(h.quota(), operationId: 'q-duplicate-key'),
      throwsA(h.problem(CloudLedgerProblem.conflict)),
    );
    await h.repo.updateQuota(
      h.quota(label: 'Bảy ngày'),
      expectedRevision: 1,
      operationId: 'q-edit',
    );
    final record = (await h.repo.watchQuotas('a').first).records.single;
    expect(record.value.snapshot.windowKey, 'weekly');
    expect(record.value.snapshot.window, 'Bảy ngày');
    expect(h.count('quotaCount'), 1);
    await h.repo.deleteQuota(
      'a',
      'weekly',
      expectedRevision: 2,
      operationId: 'q-delete',
    );
    expect(h.count('quotaCount'), 0);
    expect(
      h.store.documents.keys.any((p) => p.contains('/quota_labels/')),
      isFalse,
    );
    await expectLater(
      h.repo.updateQuota(
        h.quota(),
        expectedRevision: 2,
        operationId: 'q-stale',
      ),
      throwsA(h.problem(CloudLedgerProblem.notFound)),
    );
  });

  test(
    'stale quota retains observation and allows metadata edit only',
    () async {
      await h.create();
      await h.repo.createQuota(h.quota(), operationId: 'q-create');
      final later = FirestoreLedgerRepository(
        ownerId: 'A',
        store: h.store,
        now: () => h.now.add(const Duration(days: 8)),
      );
      addTearDown(later.close);
      await later.updateQuota(
        h.quota(label: 'Cũ'),
        expectedRevision: 1,
        operationId: 'q-label',
      );
      await expectLater(
        later.updateQuota(
          h.quota(label: 'Cũ', percent: 20),
          expectedRevision: 2,
          operationId: 'q-invalid',
        ),
        throwsA(h.problem(CloudLedgerProblem.invalidData)),
      );
      final value =
          (await later.watchQuotas('a').first).records.single.value.snapshot;
      expect(value.isStale(h.now.add(const Duration(days: 8))), isTrue);
      expect(value.usedPercent, 50);
    },
  );

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

  test(
    'quota retry after reset confirms receipt without changing snapshot',
    () async {
      await h.create();
      await h.repo.createQuota(h.quota(), operationId: 'q-create');
      final later = FirestoreLedgerRepository(
        ownerId: 'A',
        store: h.store,
        now: () => h.now.add(const Duration(days: 8)),
      );
      addTearDown(later.close);
      expect(await later.createQuota(h.quota(), operationId: 'q-create'), 1);
      expect(h.count('quotaCount'), 1);
    },
  );

  test(
    'concurrent quota create vs delete account has no orphan labels/windows',
    () async {
      await h.create();
      final results = await Future.wait([
        h.repo
            .createQuota(h.quota(), operationId: 'q-create')
            .then<Object>((v) => v, onError: (Object e) => e),
        h.repo
            .deleteAccount('a', expectedRevision: 1, operationId: 'a-delete')
            .then<Object>((_) => 'deleted', onError: (Object e) => e),
      ]);
      expect(results.whereType<CloudLedgerFailure>().length, 1);
      final hasQuota = h.store.documents.keys.any(
        (p) => p.contains('/quota_windows/'),
      );
      expect(
        hasQuota && !h.store.documents.containsKey('users/A/accounts/a'),
        isFalse,
      );
      if (hasQuota) expect(h.count('quotaCount'), 1);
    },
  );

  test('expired quota is stale and not reset to zero on read', () async {
    await h.create();
    await h.repo.createQuota(h.quota(percent: 88), operationId: 'q-create');
    final record = (await h.repo.watchQuotas('a').first).records.single;
    expect(record.value.snapshot.usedPercent, 88);
    expect(
      record.value.snapshot.isStale(h.now.add(const Duration(days: 8))),
      isTrue,
    );
    expect(record.value.snapshot.remainingPercent, 12);
  });
}
