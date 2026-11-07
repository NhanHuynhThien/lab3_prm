import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Posts a notification to the phone's notification tray.
abstract interface class AlertNotifier {
  Future<void> show(int id, String title, String body);
}

class SystemAlertNotifier implements AlertNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }();

  @override
  Future<void> show(int id, String title, String body) async {
    await _init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'token_limit',
          'Cảnh báo giới hạn token',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
