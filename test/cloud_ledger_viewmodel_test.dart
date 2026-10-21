import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/services/usage_calculator.dart';
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
  test('lost acknowledgement retry preserves original create despite stream update', () async {
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
    await expectLater(
      vm.saveUsage(usage(cost: 10), expectedRevision: 0),
      throwsStateError,
    );
    await vm.saveUsage(usage(cost: 9), expectedRevision: 0);
    await flush();
    expect(store.documents['users/A/accounts/a']!['usageCount'], 1);
    expect(vm.usageRevision('u'), 1);
  });
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
      await expectLater(
        vm.updateQuota('a', quota, expectedRevision: 0),
        throwsA(isA<CloudLedgerFailure>()),
      );
      expect(vm.quotaRevision('a', 'weekly'), 1);
      await vm.deleteQuota('a', 'weekly');
      await flush();
      expect(
        container.read(ledgerProvider).requireValue.account('a')!.quotaWindows,
        isEmpty,
      );
    },
  );
  test(
    'settings persist and stale initial create cannot override remote setting',
    () async {
      await vm.setReportingTimezone('UTC', expectedRevision: 0);
      await flush();
      expect(
        container.read(ledgerProvider).requireValue.reportingTimezone,
        'UTC',
      );
      await expectLater(
        vm.setReportingTimezone('Asia/Ho_Chi_Minh', expectedRevision: 0),
        throwsA(isA<CloudLedgerFailure>()),
      );
      await vm.setReportingTimezone('Asia/Ho_Chi_Minh', expectedRevision: 1);
      await flush();
      expect(vm.settingsRevision, 2);
    },
  );
  test('cache/pending shown but blocked for writes', () async {
    store.fromCache = true;
    store.changes.add(null);
    await flush();
    expect(vm.sync.fromCache, isTrue);
    await expectLater(
      vm.saveAccount(account()),
      throwsA(isA<CloudLedgerFailure>()),
    );
    store.fromCache = false;
    store.pending = true;
    store.changes.add(null);
    await flush();
    expect(vm.sync.pending, isTrue);
    await expectLater(
      vm.saveAccount(account()),
      throwsA(isA<CloudLedgerFailure>()),
    );
  });
  test(
    'stream error retains data/filter, stays failed until explicit retry',
    () async {
      await vm.saveAccount(account(), expectedRevision: 0);
      await flush();
      container.read(rangeProvider.notifier).select(UsageRange.week);
      store.changes.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await flush();
      expect(container.read(ledgerProvider).requireValue.accounts.length, 1);
      expect(vm.sync.error, isNotNull);
      store.changes.add(null);
      await flush();
      expect(vm.sync.confirmed, isFalse);
      await vm.retry();
      await flush();
      expect(vm.sync.confirmed, isTrue);
      expect(container.read(rangeProvider), UsageRange.week);
    },
  );
  test(
    'transient mismatched counters never publish orphan or incomplete totals',
    () async {
      await vm.saveAccount(account(), expectedRevision: 0);
      await flush();
      final parent = store.documents['users/A/accounts/a']!;
      parent['usageCount'] = 1;
      store.changes.add(null);
      await flush();
      expect(vm.sync.coherent, isFalse);
      expect(container.read(ledgerProvider).requireValue.sessions, isEmpty);
      await expectLater(
        vm.saveUsage(usage()),
        throwsA(isA<CloudLedgerFailure>()),
      );
      parent['usageCount'] = 0;
      store.changes.add(null);
      await flush();
      expect(vm.sync.confirmed, isTrue);
    },
  );
  test(
    'logout denies writes and old state cannot be used by a new container',
    () async {
      await vm.saveAccount(account(), expectedRevision: 0);
      await flush();
      store.signIn('B');
      await flush();
      expect(vm.sync.confirmed, isFalse);
      await expectLater(
        vm.saveUsage(usage()),
        throwsA(isA<CloudLedgerFailure>()),
      );
      expect(
        store.documents.keys.any((p) => p.startsWith('users/B/')),
        isFalse,
      );
    },
  );
  test('cloud cannot call local reset/clear/recovery', () async {
    await expectLater(vm.resetDemo(), throwsStateError);
    await expectLater(vm.clearDemo(), throwsStateError);
    await expectLater(vm.recoverDemo(), throwsStateError);
    expect(store.documents, isEmpty);
  });
  test('dispose during bootstrap does not attach late listeners', () async {
    final earlyStore = LedgerCloudFake();
    final early = ProviderContainer(
      overrides: [
        cloudOwnerProvider.overrideWithValue('A'),
        cloudRepositoryFactoryProvider.overrideWithValue(
          () => FirestoreLedgerRepository(ownerId: 'A', store: earlyStore),
        ),
        ledgerProvider.overrideWith(CloudLedgerViewModel.new),
      ],
    );
    early.listen(ledgerProvider, (_, _) {});
    early.dispose();
    await flush();
    expect(earlyStore.activeListeners, 0);
    expect(earlyStore.identity.hasListener, isFalse);
    await earlyStore.close();
  });
  test(
    'concurrent retry requests share a single connection and subscription set',
    () async {
      await Future.wait([vm.retry(), vm.retry()]);
      await flush();
      expect(store.activeListeners, 4);
      expect(vm.sync.confirmed, isTrue);
    },
  );
}
