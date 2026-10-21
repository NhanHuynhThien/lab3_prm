import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/services/remote_config_service.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/product_features_viewmodel.dart';
import 'package:token_ledger/viewmodels/reporting_viewmodel.dart';

import 'support/ledger_cloud_fake.dart';
import 'support/product_features_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Remote Config resilience', () {
    late FakeConfigTransport transport;
    late RemoteConfigService config;
    final now = DateTime.utc(2026, 10, 21);
    setUp(() {
      transport = FakeConfigTransport();
      config = RemoteConfigService(transport, now: () => now);
    });
    tearDown(() => config.close());
    test('defaults exist before network and match JSON deliverable', () {
      expect(config.current.recentLimit, 3);
      expect(config.current.warningPercent, 80);
      expect(
        jsonDecode(
          File('firebase/remote-config-defaults.json').readAsStringSync(),
        ),
        RemoteConfigService.defaults,
      );
    });
    test('remote values, sources and successful check time', () async {
      transport.remote(7, 45);
      await config.refresh();
      expect(config.current.recentLimit, 7);
      expect(config.current.warningPercent, 45);
      expect(config.current.recentSource, 'remote');
      expect(config.current.fetchedAt, now);
    });
    test(
      'bounds clamp and malformed values fall back without false source',
      () async {
        transport.remote(-20, 1000);
        await config.refresh();
        expect(config.current.recentLimit, 1);
        expect(config.current.warningPercent, 100);
        transport.payload = const ConfigPayload(
          {'overview_recent_limit': 'oops', 'budget_warning_percent': 'NaN'},
          {'overview_recent_limit': 'remote'},
        );
        await config.refresh();
        expect(config.current.recentLimit, 3);
        expect(config.current.warningPercent, 80);
        expect(config.current.recentSource, 'default');
      },
    );
    test(
      'fetch failure keeps last activated values and successful timestamp',
      () async {
        transport.remote(5, 65);
        await config.refresh();
        transport.fetchError = StateError('private server text');
        await config.refresh();
        expect(config.current.recentLimit, 5);
        expect(config.current.warningPercent, 65);
        expect(config.current.fetchedAt, now);
        expect(config.current.error, isNot(contains('private')));
        expect(config.current.refreshing, isFalse);
      },
    );
    test('cold fetch failure retains SDK activated cache', () async {
      transport.remote(8, 70);
      transport.fetchError = StateError('offline');
      await config.refresh();
      expect(config.current.recentLimit, 8);
      expect(config.current.error, isNotNull);
      expect(config.current.fetchedAt, isNull);
    });
    test('prepare failure retries and clears error on success', () async {
      transport.prepareError = StateError('no SDK');
      await config.refresh();
      expect(config.current.recentLimit, 3);
      transport.prepareError = null;
      transport.remote(4, 90);
      await config.refresh();
      expect(config.current.error, isNull);
      expect(config.current.recentLimit, 4);
      expect(transport.prepares, 2);
    });
    test(
      'double refresh shares request and publishes pending immediately',
      () async {
        transport.gate = Completer<void>();
        final first = config.refresh();
        final second = config.refresh();
        expect(identical(first, second), isTrue);
        expect(config.current.refreshing, isTrue);
        await Future<void>.delayed(Duration.zero);
        expect(transport.fetches, 1);
        transport.gate!.complete();
        await first;
        expect(config.current.refreshing, isFalse);
      },
    );
    test('closing during fetch ignores late response', () async {
      transport.gate = Completer<void>();
      final pending = config.refresh();
      await Future<void>.delayed(Duration.zero);
      await config.close();
      transport.remote(9, 10);
      transport.gate!.complete();
      await pending;
      expect(config.current.recentLimit, 3);
    });
  });

  test(
    'RC updates recent rows and threshold without changing totals or dataset',
    () async {
      final transport = FakeConfigTransport()..remote(1, 40);
      final config = RemoteConfigService(transport);
      final store = LedgerCloudFake();
      final now = DateTime.utc(2026, 10, 21, 9);
      final container = ProviderContainer(
        overrides: [
          remoteConfigServiceProvider.overrideWithValue(config),
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
      container.listen(dashboardProjectionProvider, (_, _) {});
      await container.read(ledgerProvider.future);
      final vm = container.read(ledgerProvider.notifier);
      await vm.saveAccount(
        AIAccount(
          id: 'a',
          alias: 'A',
          provider: 'Google',
          product: 'Gemini',
          billingMode: BillingMode.subscription,
          plan: '',
          createdAt: now,
          budgetMicros: 1000000,
        ),
        expectedRevision: 0,
      );
      for (var i = 0; i < 3; i++) {
        await vm.saveUsage(
          UsageSession(
            id: 'u$i',
            accountId: 'a',
            title: 'Work',
            purpose: Purpose.code,
            occurredAt: now,
            costMicros: 200000,
          ),
          expectedRevision: 0,
        );
      }
      await config.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      var p = container.read(dashboardProjectionProvider);
      expect(p.recentSessions, hasLength(1));
      expect(p.sessions, hasLength(3));
      expect(p.summary.costMicros, 600000);
      expect(p.budgetWarning, isTrue);
      transport.remote(10, 80);
      await config.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      p = container.read(dashboardProjectionProvider);
      expect(p.recentSessions, hasLength(3));
      expect(p.summary.costMicros, 600000);
      expect(p.budgetWarning, isFalse);
      container.dispose();
      await config.close();
      await store.close();
    },
  );
}
