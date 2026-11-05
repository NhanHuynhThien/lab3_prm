import 'dart:async';

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
  // Early in a month, so the 7-day window crosses the month boundary.
  final now = DateTime.utc(2026, 11, 3, 9);
  late LedgerCloudFake store;
  late FirestoreLedgerRepository repo;
  late ProviderContainer container;
  late CloudLedgerViewModel vm;

  AIAccount account(String id, {int? budget, bool archived = false}) =>
      AIAccount(
        id: id,
        alias: 'Account $id',
        provider: 'Anthropic',
        product: 'Claude',
        billingMode: BillingMode.api,
        plan: '',
        createdAt: now,
        budgetMicros: budget,
        archived: archived,
      );

  UsageSession usage(String id, String accountId, DateTime at, {int? cost}) =>
      UsageSession(
        id: id,
        accountId: accountId,
        title: 'Work $id',
        purpose: Purpose.code,
        occurredAt: at,
        costMicros: cost,
        costBasis: cost == null ? CostBasis.unknown : CostBasis.manual,
      );

  QuotaSnapshot quota(String window, {String? key, int used = 10}) =>
      QuotaSnapshot(
        window: window,
        windowKey: key,
        usedPercent: used,
        observedAt: now,
        resetAt: now.add(const Duration(hours: 5)),
      );

  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 10));

  ProviderContainer open(LedgerCloudFake source) {
    repo = FirestoreLedgerRepository(
      ownerId: 'A',
      store: source,
      now: () => now,
    );
    return ProviderContainer(
      overrides: [
        cloudOwnerProvider.overrideWithValue('A'),
        cloudRepositoryFactoryProvider.overrideWithValue(() => repo),
        ledgerProvider.overrideWith(CloudLedgerViewModel.new),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  }

  LedgerData data() => container.read(ledgerProvider).requireValue;

  DashboardProjection dashboard() {
    final sub = container.listen(dashboardProjectionProvider, (_, _) {});
    final value = sub.read();
    sub.close();
    return value;
  }

  FirebaseException offline() =>
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');

  setUp(() async {
    store = LedgerCloudFake();
    container = open(store);
    container.listen(ledgerProvider, (_, _) {});
    await container.read(ledgerProvider.future);
    vm = container.read(ledgerProvider.notifier) as CloudLedgerViewModel;
  });

  tearDown(() async {
    container.dispose();
    await flush();
    await store.close();
  });

  group('dashboard figures', () {
    test('7-day chart keeps last month while range is this month', () async {
      await vm.saveAccount(account('a'), expectedRevision: 0);
      await flush();
      final oct30 = DateTime.utc(2026, 10, 30, 9);
      await vm.saveUsage(
        usage('u', 'a', oct30, cost: 2000000),
        expectedRevision: 0,
      );
      await flush();
      expect(container.read(rangeProvider), UsageRange.month);
      expect(dashboard().sessions, isEmpty);
      expect(dashboard().dailyCosts, contains(2000000));
    });

    test('one exceeded account warns despite a healthy total', () async {
      await vm.saveAccount(account('a', budget: 20000000), expectedRevision: 0);
      await flush();
      await vm.saveAccount(
        account('b', budget: 100000000),
        expectedRevision: 0,
      );
      await flush();
      await vm.saveUsage(
        usage('u', 'a', now, cost: 40000000),
        expectedRevision: 0,
      );
      await flush();
      final view = dashboard();
      expect(view.spent, 40000000);
      expect(view.budget, 120000000);
      expect(view.budgetWarning, isTrue);
      expect(view.budgetAlerts.single.account.id, 'a');
      expect(view.budgetAlerts.single.exceeded, isTrue);
    });

    test('nothing warns below every threshold', () async {
      await vm.saveAccount(account('a', budget: 20000000), expectedRevision: 0);
      await flush();
      await vm.saveUsage(
        usage('u', 'a', now, cost: 1000000),
        expectedRevision: 0,
      );
      await flush();
      expect(dashboard().budgetWarning, isFalse);
    });

    test('budget reports sessions in the cycle with unknown cost', () async {
      await vm.saveAccount(account('a', budget: 20000000), expectedRevision: 0);
      await flush();
      await vm.saveUsage(usage('u', 'a', now), expectedRevision: 0);
      await flush();
      expect(dashboard().budgetUnknownCost, 1);
    });
  });

  group('quota windows', () {
    setUp(() async {
      await vm.saveAccount(account('a'), expectedRevision: 0);
      await flush();
      await vm.updateQuota('a', quota('5 giờ'), expectedRevision: 0);
      await flush();
    });

    test('adding a duplicate name updates that window', () async {
      await vm.updateQuota('a', quota('5 Giờ ', used: 70), expectedRevision: 0);
      await flush();
      final windows = data().account('a')!.quotaWindows;
      expect(windows, hasLength(1));
      expect(windows.single.usedPercent, 70);
    });

    test('a new window can reuse the old name of a renamed one', () async {
      await vm.updateQuota(
        'a',
        quota('Tuần', key: '5 giờ'),
        requireExisting: true,
        expectedRevision: vm.quotaRevision('a', '5 giờ'),
      );
      await flush();
      await vm.updateQuota('a', quota('5 giờ', used: 30), expectedRevision: 0);
      await flush();
      final windows = data().account('a')!.quotaWindows;
      expect(windows.map((q) => q.window), unorderedEquals(['Tuần', '5 giờ']));
    });

    test('archived account gets a clear reason, not a conflict', () async {
      await vm.archiveAccount('a', true);
      await flush();
      expect(
        () => vm.updateQuota('a', quota('Khác'), expectedRevision: 0),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('lưu trữ'),
          ),
        ),
      );
    });
  });

  group('save with unknown outcome', () {
    setUp(() async {
      await vm.saveAccount(account('a'), expectedRevision: 0);
      await flush();
    });

    test('edited draft saves after the first attempt never landed', () async {
      store.failNext = offline();
      final first = usage('u', 'a', now, cost: 1000000);
      await expectLater(
        vm.saveUsage(first, expectedRevision: 0),
        throwsA(isA<CloudLedgerFailure>()),
      );
      expect(vm.hasUnconfirmed('usage/u'), isTrue);
      await vm.saveUsage(
        usage('u', 'a', now, cost: 2000000),
        expectedRevision: 0,
      );
      await flush();
      expect(vm.hasUnconfirmed('usage/u'), isFalse);
      expect(data().sessions.single.costMicros, 2000000);
      expect(data().account('a'), isNotNull);
      expect(store.documents['users/A/accounts/a']!['usageCount'], 1);
    });

    test('edited draft updates when the first attempt did land', () async {
      store.failAfterCommit = offline();
      await expectLater(
        vm.saveUsage(usage('u', 'a', now, cost: 1000000), expectedRevision: 0),
        throwsA(isA<CloudLedgerFailure>()),
      );
      await flush();
      await vm.saveUsage(
        usage('u', 'a', now, cost: 2000000),
        expectedRevision: 0,
      );
      await flush();
      expect(data().sessions, hasLength(1));
      expect(data().sessions.single.costMicros, 2000000);
      expect(store.documents['users/A/accounts/a']!['usageCount'], 1);
    });
  });

  group('startup without server confirmation', () {
    test(
      'an empty cache snapshot is not shown as an empty workspace',
      () async {
        final cold = LedgerCloudFake()..fromCache = true;
        final local = open(cold);
        local.listen(ledgerProvider, (_, _) {});
        await flush();
        expect(local.read(ledgerProvider).isLoading, isTrue);
        expect(local.read(cloudSyncProvider).label, 'Đang đồng bộ');
        cold.fromCache = false;
        cold.changes.add(null);
        await flush();
        expect(local.read(ledgerProvider).requireValue.accounts, isEmpty);
        local.dispose();
        await flush();
        await cold.close();
      },
    );

    test('offline retry keeps last-good data', () async {
      await vm.saveAccount(account('a'), expectedRevision: 0);
      await flush();
      store.fromCache = true;
      final documents = Map.of(store.documents);
      store.documents.clear();
      unawaited(vm.retry().catchError((_) {}));
      await flush();
      expect(data().accounts, hasLength(1));
      store.documents.addAll(documents);
      store.fromCache = false;
      store.changes.add(null);
      await flush();
    });
  });
}
