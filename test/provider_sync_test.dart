import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:token_ledger/models/cloud_sync_status.dart';
import 'package:token_ledger/models/provider_usage.dart';
import 'package:token_ledger/services/provider_sync_service.dart';
import 'package:token_ledger/viewmodels/provider_sync_viewmodel.dart';

import 'support/provider_sync_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final token = 'a' * 64;
  final now = DateTime.utc(2026, 10, 21, 12);

  test(
    'unknown fields stay unknown and quota expires without resetting to 100',
    () {
      final value = ProviderSnapshot.fromJson(syncFixture(now: now));
      final claude = value.providers[1];
      expect(claude.totalTokens, isNull);
      expect(claude.contextTokens, 1200);
      expect(claude.remaining(claude.windows.first, now), 75);
      expect(
        claude.remaining(
          claude.windows.first,
          now.add(const Duration(minutes: 16)),
        ),
        isNull,
      );
      expect(
        claude.remaining(
          claude.windows.first,
          now.add(const Duration(hours: 6)),
        ),
        isNull,
      );
      expect(value.providers[0].estimatedCostMicros, isNull);
      expect(value.providers[0].models.first.model, 'codex-test-model');
    },
  );

  test('reject unsupported schemas, duplicate provider/model and invalid numeric data', () {
    final badSchema = syncFixture()..['schemaVersion'] = 20;
    expect(() => ProviderSnapshot.fromJson(badSchema), throwsFormatException);
    final duplicate = syncFixture();
    duplicate['providers'][1]['id'] = 'codex';
    expect(() => ProviderSnapshot.fromJson(duplicate), throwsFormatException);
    for (final bad in [-1, double.nan, 2.5, '120']) {
      final data = syncFixture();
      data['providers'][0]['models'][0]['totalTokens'] = bad;
      expect(() => ProviderSnapshot.fromJson(data), throwsFormatException);
    }
    final data = syncFixture();
    data['providers'][0]['windows'][0]['usedPercent'] = 101;
    expect(() => ProviderSnapshot.fromJson(data), throwsFormatException);
  });

  test('HTTP uses authenticated fixed loopback, no redirects; errors never expose server body', () async {
    final service = LoopbackProviderSync(
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://127.0.0.1:8787/v1/snapshot');
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(request.followRedirects, isFalse);
        return http.Response(
          jsonEncode(syncFixture()),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    expect((await service.fetch(token)).providers.length, 3);
    await expectLater(
      service.fetch('oauth-secret'),
      throwsA(isA<ProviderSyncFailure>()),
    );
    service.close();
    final denied = LoopbackProviderSync(
      client: MockClient((_) async => http.Response('SECRET TOKEN', 401)),
    );
    try {
      await denied.fetch(token);
      fail('Expected auth error');
    } on ProviderSyncFailure catch (e) {
      expect(e.message, isNot(contains('SECRET')));
    }
    denied.close();
    final tried = <String>[];
    final fallback = LoopbackProviderSync(
      endpoints: [
        Uri.parse('http://127.0.0.1:8787/v1/snapshot'),
        Uri.parse('http://10.0.2.2:8787/v1/snapshot'),
      ],
      client: MockClient((request) async {
        tried.add(request.url.host);
        if (request.url.host == '127.0.0.1') {
          throw http.ClientException('refused');
        }
        return http.Response(
          jsonEncode(syncFixture()),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    expect((await fallback.fetch(token)).providers.length, 3);
    expect(tried, ['127.0.0.1', '10.0.2.2']);
    fallback.close();
  });

  test('figures are saved per account and shown on next login', () async {
    final store = FakeSnapshotStore();
    ProviderContainer open(String uid, FakeProviderSync service) =>
        ProviderContainer(
          overrides: [
            cloudOwnerProvider.overrideWithValue(uid),
            providerSyncServiceProvider.overrideWithValue(service),
            providerSnapshotStoreProvider.overrideWithValue(store),
          ],
        );
    final first = open('A', FakeProviderSync());
    await first.read(providerSyncProvider.notifier).connect(token);
    expect(store.saved['A']?.raw, isNotNull);
    first.dispose();

    final service = FakeProviderSync();
    final again = open('A', service);
    again.read(providerSyncProvider);
    await pumpEventQueue();
    expect(again.read(providerSyncProvider).snapshot?.providers, isNotEmpty);
    expect(again.read(providerSyncProvider).enabled, isFalse);
    expect(service.calls, 0, reason: 'no companion needed to show saved data');
    again.dispose();

    final other = open('B', FakeProviderSync());
    other.read(providerSyncProvider);
    await pumpEventQueue();
    expect(other.read(providerSyncProvider).snapshot, isNull);
    other.dispose();
  });

  test(
    'VM single-flight, last-good retry and disconnect ignore late responses',
    () async {
      final service = FakeProviderSync();
      final container = ProviderContainer(
        overrides: [
          cloudOwnerProvider.overrideWithValue('A'),
          providerSyncServiceProvider.overrideWithValue(service),
        ],
      );
      try {
        final actions = container.read(providerSyncProvider.notifier);
        await actions.connect(token);
        final good = container.read(providerSyncProvider).snapshot;
        service.error = const ProviderSyncFailure('Nguồn offline');
        await actions.refresh();
        expect(container.read(providerSyncProvider).snapshot, same(good));
        expect(container.read(providerSyncProvider).error, 'Nguồn offline');
        service.error = null;
        service.gate = Completer<ProviderSnapshot>();
        final refresh = actions.refresh();
        await actions.refresh();
        expect(service.calls, 3);
        actions.disconnect();
        service.gate!.complete(service.value);
        await refresh;
        expect(container.read(providerSyncProvider).snapshot, isNull);
        expect(container.read(providerSyncProvider).enabled, isFalse);
      } finally {
        container.dispose();
      }
    },
  );

  test('demo cannot connect and workspace containers never inherit another UID data', () async {
    final service = FakeProviderSync();
    final demo = ProviderContainer(
      overrides: [providerSyncServiceProvider.overrideWithValue(service)],
    );
    final a = ProviderContainer(
      overrides: [
        cloudOwnerProvider.overrideWithValue('A'),
        providerSyncServiceProvider.overrideWithValue(service),
      ],
    );
    final b = ProviderContainer(
      overrides: [
        cloudOwnerProvider.overrideWithValue('B'),
        providerSyncServiceProvider.overrideWithValue(service),
      ],
    );
    try {
      await demo.read(providerSyncProvider.notifier).connect(token);
      expect(service.calls, 0);
      await a.read(providerSyncProvider.notifier).connect(token);
      expect(b.read(providerSyncProvider).snapshot, isNull);
      a.dispose();
      expect(b.read(providerSyncProvider).enabled, isFalse);
    } finally {
      demo.dispose();
      b.dispose();
    }
  });

  test(
    'future source timestamp is rejected without losing last-good',
    () async {
      final service = FakeProviderSync();
      final c = ProviderContainer(
        overrides: [
          cloudOwnerProvider.overrideWithValue('A'),
          providerSyncServiceProvider.overrideWithValue(service),
        ],
      );
      try {
        final vm = c.read(providerSyncProvider.notifier);
        await vm.connect(token);
        final previous = c.read(providerSyncProvider).snapshot;
        service.value = ProviderSnapshot.fromJson(
          syncFixture(now: DateTime.now().toUtc().add(const Duration(days: 1))),
        );
        await vm.refresh();
        expect(c.read(providerSyncProvider).snapshot, same(previous));
        expect(c.read(providerSyncProvider).error, isNotNull);
      } finally {
        c.dispose();
      }
    },
  );
}
