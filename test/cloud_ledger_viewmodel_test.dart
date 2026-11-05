import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/reporting_viewmodel.dart';

import 'support/ledger_cloud_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 21, 9);
  late LedgerCloudFake store;
  late FirestoreLedgerRepository repo;
  late ProviderContainer container;
  late CloudLedgerViewModel vm;
  var disposed = false;
  AIAccount account() => AIAccount(
    id: 'a',
    alias: 'Account A',
    provider: 'Anthropic',
    product: 'Claude',
    billingMode: BillingMode.subscription,
    plan: '',
    createdAt: now,
    budgetMicros: 1000000,
  );
  UsageSession usage({int? cost}) => UsageSession(
    id: 'u',
    accountId: 'a',
    title: 'Work',
    purpose: Purpose.code,
    occurredAt: now,
    costMicros: cost,
  );
  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 10));
  setUp(() async {
    disposed = false;
    store = LedgerCloudFake();
    repo = FirestoreLedgerRepository(
      ownerId: 'A',
      store: store,
      now: () => now,
    );
    container = ProviderContainer(
      overrides: [
        cloudOwnerProvider.overrideWithValue('A'),
        cloudRepositoryFactoryProvider.overrideWithValue(() => repo),
        ledgerProvider.overrideWith(CloudLedgerViewModel.new),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    container.listen(ledgerProvider, (_, _) {});
    await container.read(ledgerProvider.future);
    vm = container.read(ledgerProvider.notifier) as CloudLedgerViewModel;
  });
  tearDown(() async {
    if (!disposed) container.dispose();
    await flush();
    await store.close();
  });
  test('cloud new user is empty and all four listeners are disposed', () async {
    expect(container.read(ledgerProvider).requireValue.accounts, isEmpty);
    expect(store.documents, isEmpty);
    expect(store.activeListeners, 4);
    expect(vm.sync.confirmed, isTrue);
    container.dispose();
    disposed = true;
    await flush();
    expect(store.activeListeners, 0);
  });
  test(
    'CRUD feeds shared dashboard totals from streams, no guessed next state',
    () async {
      await vm.saveAccount(account(), expectedRevision: 0);
      await flush();
      await vm.saveUsage(usage(cost: 12345), expectedRevision: 0);
      await flush();
      final projection = container.read(dashboardProjectionProvider);
      expect(projection.summary.costMicros, 12345);
      expect(projection.summary.count, 1);
      expect(vm.usageRevision('u'), 1);
      await vm.saveUsage(usage(cost: 7), expectedRevision: 1);
      await flush();
      expect(container.read(dashboardProjectionProvider).summary.costMicros, 7);
      await vm.deleteUsage('u');
      await flush();
      await vm.deleteAccount('a');
      await flush();
      expect(container.read(ledgerProvider).requireValue.accounts, isEmpty);
    },
  );
  test(
    'failed save keeps last good dataset and retry stable operation',
    () async {
      await vm.saveAccount(account(), expectedRevision: 0);
      await flush();
      store.failNext = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      await expectLater(
        vm.saveUsage(usage(cost: 9), expectedRevision: 0),
        throwsA(isA<CloudLedgerFailure>()),
      );
      expect(container.read(ledgerProvider).requireValue.sessions, isEmpty);
      await vm.saveUsage(usage(cost: 9), expectedRevision: 0);
      await flush();
      expect(container.read(ledgerProvider).requireValue.sessions.length, 1);
    },
  );
  test(
    'lost acknowledgement: edited retry updates, never duplicates',
    () async {
      await vm.saveAccount(account(), expectedRevision: 0);
      await flush();
      store.failAfterCommit = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      await expectLater(
        vm.saveUsage(usage(cost: 9), expectedRevision: 0),
        throwsA(isA<CloudLedgerFailure>()),
      );
      await flush();
      await vm.saveUsage(usage(cost: 9), expectedRevision: 0);
      await flush();
      expect(vm.usageRevision('u'), 1);
      store.failAfterCommit = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      await expectLater(
        vm.saveUsage(usage(cost: 10), expectedRevision: 1),
        throwsA(isA<CloudLedgerFailure>()),
      );
      await flush();
      await vm.saveUsage(usage(cost: 11), expectedRevision: 1);
      await flush();
      expect(store.documents['users/A/accounts/a']!['usageCount'], 1);
      expect(vm.usageRevision('u'), 3);
      expect(
        container.read(ledgerProvider).requireValue.sessions.single.costMicros,
        11,
      );
    },
  );
  test('stale form revision cannot overwrite remote metadata', () async {
    await vm.saveAccount(account(), expectedRevision: 0);
    await flush();
    await repo.updateAccount(
      account().copyWith(alias: 'Remote'),
      expectedRevision: 1,
      operationId: 'remote',
    );
    await flush();
    await expectLater(
      vm.saveAccount(account().copyWith(alias: 'Stale'), expectedRevision: 1),
      throwsA(isA<CloudLedgerFailure>()),
    );
    expect(
      container.read(ledgerProvider).requireValue.account('a')!.alias,
      'Remote',
    );
  });
  test(
    'cloud snapshots join quotas before rendering and retain percent semantics',
    () async {
      await vm.saveAccount(account(), expectedRevision: 0);
      await flush();
      final quota = QuotaSnapshot(
        windowKey: 'weekly',
        window: 'Tuần',
        usedPercent: 75,
        observedAt: now,
        resetAt: now.add(const Duration(days: 7)),
      );
      await vm.updateQuota('a', quota, expectedRevision: 0);
      await flush();
      expect(
        container
            .read(ledgerProvider)
            .requireValue
            .account('a')!
            .quotaWindows
            .single
            .usedPercent,
        75,
      );
      // Adding a window under an existing name updates that window.
      await vm.updateQuota('a', quota, expectedRevision: 0);
      await flush();
      expect(vm.quotaRevision('a', 'weekly'), 2);
      await vm.deleteQuota('a', 'weekly');
      await flush();
      expect(
        container.read(ledgerProvider).requireValue.account('a')!.quotaWindows,
        isEmpty,
      );
    },
  );
}
