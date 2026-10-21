import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/analytics_service.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/product_features_viewmodel.dart';

import 'support/ledger_cloud_fake.dart';
import 'support/product_features_harness.dart';

export 'support/product_features_harness.dart'
    show FakeAnalyticsTransport, FakeConfigTransport;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Analytics privacy and lifecycle', () {
    late FakeAnalyticsTransport transport;
    late AnalyticsService service;
    setUp(() {
      transport = FakeAnalyticsTransport();
      service = AnalyticsService(transport);
    });
    tearDown(() async {
      transport.error = null;
      transport.identifyGate = null;
      await service.close();
    });
    test('signed out and invalid fields send nothing', () async {
      await service.record(ProductEvent.screen('overview'));
      await service.record(ProductEvent.screen('private work title'));
      expect(transport.events, isEmpty);
      expect(ProductEvent.detail('email@example.test'), isNull);
      expect(ProductEvent.mutation('private account', 'create'), isNull);
      expect(ProductEvent.mutation('usage', 'secret'), isNull);
    });
    test(
      'identity is set before login; repeat owner does not duplicate',
      () async {
        await service.setOwner('A');
        await service.setOwner('A');
        expect(transport.events.map((e) => e.name), ['login']);
        expect(transport.events.single.uid, 'A');
        expect(
          transport.calls.indexOf('identify:A'),
          lessThan(transport.calls.indexOf('event:login')),
        );
      },
    );
    test(
      'logout precedes clear and signed-out business events are dropped',
      () async {
        await service.setOwner('A');
        await service.setOwner(null);
        await service.record(ProductEvent.mutation('usage', 'create'));
        expect(transport.events.map((e) => e.name), ['login', 'logout']);
        expect(transport.events.last.uid, 'A');
        expect(transport.uid, isNull);
        expect(service.current.enabled, isFalse);
      },
    );
    test('queued A work is dropped during switch to B', () async {
      await service.setOwner('A');
      final old = service.record(ProductEvent.detail('account'));
      final next = service.setOwner('B');
      await Future.wait([old, next]);
      await service.record(ProductEvent.detail('usage'));
      expect(transport.events.where((e) => e.name == 'view_account'), isEmpty);
      expect(transport.events.last.uid, 'B');
    });
    test('logout during pending identity never enables stale A', () async {
      transport.identifyGate = Completer<void>();
      final old = service.setOwner('A');
      await Future<void>.delayed(Duration.zero);
      final leave = service.setOwner(null);
      transport.identifyGate!.complete();
      await Future.wait([old, leave]);
      expect(transport.events, isEmpty);
      expect(transport.uid, isNull);
    });
    test(
      'mutation retry operation ID dedupes but different operations emit',
      () async {
        await service.setOwner('A');
        await service.record(
          ProductEvent.mutation('usage', 'create'),
          operationId: 'op',
        );
        await service.record(
          ProductEvent.mutation('usage', 'create'),
          operationId: 'op',
        );
        await service.record(
          ProductEvent.mutation('usage', 'create'),
          operationId: 'next',
        );
        expect(
          transport.events.where((e) => e.name == 'usage_saved'),
          hasLength(2),
        );
      },
    );
    test(
      'SDK failure is sanitized, retryable and never throws to caller',
      () async {
        transport.error = StateError('email and token must never escape');
        await service.setOwner('A');
        expect(service.current.error, isNotNull);
        expect(service.current.error, isNot(contains('token')));
        transport.error = null;
        await service.setOwner('A');
        expect(service.current.enabled, isTrue);
      },
    );
    test('payload is immutable and contains only static enum data', () async {
      final event = ProductEvent.mutation('account', 'update')!;
      expect(
        () => event.parameters['email'] = 'secret',
        throwsUnsupportedError,
      );
      await service.setOwner('A');
      await service.record(event, operationId: 'do-not-send-this');
      expect(transport.events.last.parameters, {'action': 'update'});
      expect(
        jsonEncode(transport.events.last.parameters),
        isNot(contains('do-not-send-this')),
      );
    });
    test('failed logout event still clears SDK identity', () async {
      await service.setOwner('A');
      transport.error = StateError('event backend failure');
      await service.setOwner(null);
      expect(transport.uid, isNull);
      expect(service.current.error, isNotNull);
    });
  });

  test('cloud events follow confirmed mutation, do not leak payload, SDK failure cannot undo save', () async {
    final backend = FakeAnalyticsTransport();
    final analytics = AnalyticsService(backend);
    await analytics.setOwner('A');
    final store = LedgerCloudFake();
    final now = DateTime.utc(2026, 10, 21, 9);
    final container = ProviderContainer(
      overrides: [
        analyticsServiceProvider.overrideWithValue(analytics),
        cloudOwnerProvider.overrideWithValue('A'),
        cloudRepositoryFactoryProvider.overrideWithValue(
          () => FirestoreLedgerRepository(
            ownerId: 'A',
            store: store,
            now: () => now,
          ),
        ),
        ledgerProvider.overrideWith(CloudLedgerViewModel.new),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    container.listen(ledgerProvider, (_, _) {});
    await container.read(ledgerProvider.future);
    final vm = container.read(ledgerProvider.notifier);
    final account = AIAccount(
      id: 'a',
      alias: 'PRIVATE NAME',
      provider: 'Google',
      product: 'Gemini',
      billingMode: BillingMode.subscription,
      plan: '',
      createdAt: now,
      budgetMicros: 1000000,
    );
    store.failNext = StateError('offline');
    await expectLater(
      vm.saveAccount(account, expectedRevision: 0),
      throwsA(anything),
    );
    await Future<void>.delayed(Duration.zero);
    expect(backend.events.where((e) => e.name == 'account_saved'), isEmpty);
    await vm.saveAccount(account, expectedRevision: 0);
    await Future<void>.delayed(Duration.zero);
    expect(
      backend.events.where((e) => e.name == 'account_saved'),
      hasLength(1),
    );
    expect(
      jsonEncode(backend.events.last.parameters),
      isNot(contains('PRIVATE')),
    );
    backend.error = StateError('analytics unavailable');
    await vm.saveUsage(
      UsageSession(
        id: 'u',
        accountId: 'a',
        title: 'PRIVATE TITLE',
        purpose: Purpose.code,
        occurredAt: now,
        costMicros: 500000,
      ),
      expectedRevision: 0,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(ledgerProvider).requireValue.sessions, hasLength(1));
    expect(analytics.current.error, isNotNull);
    container.dispose();
    backend.error = null;
    await analytics.close();
    await store.close();
  });
}
