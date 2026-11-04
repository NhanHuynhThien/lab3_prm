import '../models/notification_item.dart';

abstract interface class NotificationTransport {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Stream<NotificationItem> get onForegroundNotification;
  Stream<NotificationItem> get onNotificationOpened;
  Future<NotificationItem?> getInitialNotification();
}

abstract interface class NotificationRefreshTransport {
  Stream<String> get onTokenRefresh;
  Future<bool> hasPermission();
  Future<void> deleteToken();
}

abstract interface class NotificationStore {
  Future<void> register(String uid, String token);
  Future<void> unregister(String uid);
  Future<List<NotificationItem>> inbox(String uid);
  Future<void> read(String uid, String id);
}
