import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/models/notification_item.dart';
import 'package:token_ledger/services/gemini_aggregate.dart';
import 'package:token_ledger/services/notification_service.dart';
import 'package:token_ledger/services/platform_api_service.dart';

void main() {
  test('API rejects owner change while obtaining token without transmitting request', () async {
    String? owner = 'a';
    final token = Completer<String?>();
    var requests = 0;
    final api = PlatformApiService(
      owner: () => owner,
      tokenFor: (_) => token.future,
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    final request = api.request('a', '/v1/me/notifications');
    final check = expectLater(request, throwsA(isA<PlatformFailure>()));
    owner = 'b';
    token.complete('never-transmit');
    await check;
    expect(requests, 0);
    api.close();
  });
  test(
    'API rejects completion after logout and redacts transport errors',
    () async {
      String? owner = 'a';
      final response = Completer<http.Response>();
      final api = PlatformApiService(
        owner: () => owner,
        tokenFor: (_) async => 'test-token',
        client: MockClient((_) => response.future),
      );
      final request = api.request('a', '/v1/me/notifications');
      final check = expectLater(request, throwsA(isA<PlatformFailure>()));
      await Future<void>.delayed(Duration.zero);
      owner = null;
      response.complete(http.Response('{"private":"old owner"}', 200));
      await check;
      api.close();
      expect(
        () => PlatformApiService(
          owner: () => null,
          tokenFor: (_) async => null,
          baseUrl: 'http://remote.invalid',
        ),
        throwsArgumentError,
      );
    },
  );
  test('Gemini aggregate omits private text, tracks unknowns and excludes demo/future', () {
    final now = DateTime.utc(2026, 11, 4);
    UsageSession session(
      String id, {
      int? input = 10,
      int? output = 20,
      int? cost = 100,
      bool demo = false,
      DateTime? at,
    }) => UsageSession(
      id: id,
      accountId: 'private-account',
      title: 'PRIVATE TITLE',
      note: 'PRIVATE NOTE',
      purpose: Purpose.code,
      occurredAt: at ?? now.subtract(const Duration(hours: 1)),
      inputTokens: input,
      outputTokens: output,
      costMicros: cost,
      isDemo: demo,
    );
    final aggregate = GeminiAggregate([
      session('a'),
      session('b', input: null, output: null, cost: null),
      session('demo', demo: true),
      session('future', at: now.add(const Duration(days: 1))),
    ], now);
    expect(aggregate.sessionCount, 2);
    expect(aggregate.totalTokens, 30);
    expect(aggregate.costMicros, 100);
    expect(aggregate.knownTokenSessions, 1);
    expect(aggregate.knownCostSessions, 1);
    final encoded = jsonEncode(aggregate.payload);
    expect(encoded.contains('PRIVATE'), false);
    expect(encoded.contains('private-account'), false);
    expect(aggregate.payload['inputTokens'], null);
    final code = (aggregate.payload['details'] as List).first as Map;
    expect(code['unknownTokenSessions'], 1);
    expect(code['unknownCostSessions'], 1);
  });
  test('notifications persist registration, guard owners/routes and clear pending on logout', () async {
    final transport = FakeRefreshTransport(), store = FakeNotificationStore();
    final service = NotificationService(transport, backend: store);
    await service.bindOwner('a');
    expect(service.registered, true);
    expect(store.registrations, ['a']);
    final routes = <String>[];
    final subscription = service.onTargetRouteRequested.listen(routes.add);
    NotificationItem item(String owner, String route) => NotificationItem(
      id: 'id',
      title: 'QA',
      body: 'QA',
      receivedAt: DateTime.now(),
      route: route,
      data: {'ownerUid': owner},
    );
    service.addNotification(item('b', '/analytics'));
    expect(service.items, isEmpty);
    service.openNotification(item('a', 'https://untrusted.invalid'));
    expect(routes, isEmpty);
    service.openNotification(item('a', '/analytics'));
    await Future<void>.delayed(Duration.zero);
    expect(routes, ['/analytics']);
    expect(service.takePendingRoute(), '/analytics');
    expect(service.takePendingRoute(), null);
    await service.detach();
    expect(store.unregistered, ['a']);
    expect(transport.deleted, true);
    expect(service.items, isEmpty);
    expect(service.ownerId, null);
    await subscription.cancel();
    await service.close();
    await transport.close();
  });
}

class FakeNotificationStore implements NotificationStore {
  final registrations = <String>[], unregistered = <String>[];
  @override
  Future<void> register(String uid, String token) async {
    registrations.add(uid);
  }

  @override
  Future<void> unregister(String uid) async {
    unregistered.add(uid);
  }

  @override
  Future<List<NotificationItem>> inbox(String uid) async => [];
  @override
  Future<void> read(String uid, String id) async {}
}

class FakeRefreshTransport
    implements NotificationTransport, NotificationRefreshTransport {
  final foreground = StreamController<NotificationItem>.broadcast(),
      opened = StreamController<NotificationItem>.broadcast(),
      tokens = StreamController<String>.broadcast();
  bool deleted = false;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<String?> getToken() async => 'test-device-token';
  @override
  Future<void> deleteToken() async {
    deleted = true;
  }

  @override
  Future<NotificationItem?> getInitialNotification() async => null;
  @override
  Stream<NotificationItem> get onForegroundNotification => foreground.stream;
  @override
  Stream<NotificationItem> get onNotificationOpened => opened.stream;
  @override
  Stream<String> get onTokenRefresh => tokens.stream;
  Future<void> close() async {
    await foreground.close();
    await opened.close();
    await tokens.close();
  }
}
