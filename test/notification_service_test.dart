import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/notification_item.dart';
import 'package:token_ledger/services/notification_service.dart';

class FakeNotificationTransport implements NotificationTransport {
  bool permission = true;
  String? token = 'sample_fcm_token_123';
  final foregroundController = StreamController<NotificationItem>.broadcast();
  final openedController = StreamController<NotificationItem>.broadcast();
  NotificationItem? initial;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<NotificationItem> get onForegroundNotification =>
      foregroundController.stream;

  @override
  Stream<NotificationItem> get onNotificationOpened => openedController.stream;

  @override
  Future<NotificationItem?> getInitialNotification() async => initial;
}

void main() {
  group('NotificationService', () {
    late FakeNotificationTransport transport;
    late NotificationService service;

    setUp(() {
      transport = FakeNotificationTransport();
      service = NotificationService(transport);
    });

    tearDown(() async {
      await service.close();
      await transport.foregroundController.close();
      await transport.openedController.close();
    });

    test(
      'bindOwner seeds welcome notification and requests permission',
      () async {
        await service.bindOwner('user_test_uid');

        expect(service.permissionGranted, isTrue);
        expect(service.deviceToken, 'sample_fcm_token_123');
        expect(service.items, isNotEmpty);
        expect(service.items.first.id, 'welcome_notification');
        expect(service.unreadCount, 1);
      },
    );

    test('addNotification prepends item and dedupes by id', () {
      final notif1 = NotificationItem(
        id: 'msg_1',
        title: 'Cảnh báo 1',
        body: 'Nội dung 1',
        receivedAt: DateTime.now(),
      );
      final notif2 = NotificationItem(
        id: 'msg_2',
        title: 'Cảnh báo 2',
        body: 'Nội dung 2',
        receivedAt: DateTime.now(),
      );

      service.addNotification(notif1);
      service.addNotification(notif2);

      expect(service.items, hasLength(2));
      expect(service.items.first.id, 'msg_2');

      // Update existing item
      final notif1Updated = notif1.copyWith(title: 'Cảnh báo 1 sửa đổi');
      service.addNotification(notif1Updated);

      expect(service.items, hasLength(2));
      expect(service.items.last.title, 'Cảnh báo 1 sửa đổi');
    });

    test('markAsRead and markAllAsRead update read status', () {
      service.addNotification(
        NotificationItem(
          id: 'item_a',
          title: 'A',
          body: 'A',
          receivedAt: DateTime.now(),
        ),
      );
      service.addNotification(
        NotificationItem(
          id: 'item_b',
          title: 'B',
          body: 'B',
          receivedAt: DateTime.now(),
        ),
      );

      expect(service.unreadCount, 2);

      service.markAsRead('item_a');
      expect(service.unreadCount, 1);
      expect(service.items.firstWhere((i) => i.id == 'item_a').isRead, isTrue);

      service.markAllAsRead();
      expect(service.unreadCount, 0);
    });

    test('clearAll empties the notification center', () {
      service.sendDemoNotification();
      expect(service.items, isNotEmpty);

      service.clearAll();
      expect(service.items, isEmpty);
      expect(service.unreadCount, 0);
    });

    test('bindOwner(null) clears state and resets device token', () async {
      await service.bindOwner('uid_123');
      expect(service.items, isNotEmpty);

      await service.bindOwner(null);
      expect(service.items, isEmpty);
      expect(service.deviceToken, isNull);
    });
  });
}
