import 'dart:async';

import '../models/notification_item.dart';

abstract interface class NotificationTransport {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Stream<NotificationItem> get onForegroundNotification;
  Stream<NotificationItem> get onNotificationOpened;
  Future<NotificationItem?> getInitialNotification();
}

class NotificationService {
  NotificationService(this._transport) {
    _initListeners();
  }

  final NotificationTransport? _transport;
  final _notificationsController =
      StreamController<List<NotificationItem>>.broadcast(sync: true);
  final _openedRouteController = StreamController<String>.broadcast(sync: true);

  final List<NotificationItem> _items = [];
  String? _ownerId;
  String? _deviceToken;
  bool _permissionGranted = false;
  bool _closed = false;

  Stream<List<NotificationItem>> get notificationsStream =>
      _notificationsController.stream;
  Stream<String> get onTargetRouteRequested => _openedRouteController.stream;

  String? get ownerId => _ownerId;
  List<NotificationItem> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((i) => !i.isRead).length;
  String? get deviceToken => _deviceToken;
  bool get permissionGranted => _permissionGranted;

  void _initListeners() {
    if (_transport == null) return;
    _transport.onForegroundNotification.listen((item) {
      addNotification(item);
    });
    _transport.onNotificationOpened.listen((item) {
      addNotification(item);
      if (item.route != null && item.route!.isNotEmpty) {
        _openedRouteController.add(item.route!);
      }
    });
  }

  Future<bool> requestPermission() async {
    if (_transport == null) return true;
    try {
      final granted = await _transport.requestPermission();
      _permissionGranted = granted;
      if (granted) {
        _deviceToken = await _transport.getToken();
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<void> bindOwner(String? uid) async {
    if (_closed) return;
    _ownerId = uid;
    if (uid != null) {
      await requestPermission();
      // Seed with initial contextual reminder if empty
      if (_items.isEmpty) {
        _items.add(
          NotificationItem(
            id: 'welcome_notification',
            title: 'Chào mừng bạn đến với TokenLedger',
            body: 'Bạn đã đăng nhập thành công. Hãy theo dõi ngân sách và mức sử dụng token hàng tháng.',
            receivedAt: DateTime.now(),
            isRead: false,
            route: '/overview',
          ),
        );
        _publish();
      }
    } else {
      _items.clear();
      _deviceToken = null;
      _publish();
    }
  }

  void addNotification(NotificationItem item) {
    if (_closed) return;
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex] = item;
    } else {
      _items.insert(0, item);
    }
    _publish();
  }

  void markAsRead(String id) {
    if (_closed) return;
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0 && !_items[index].isRead) {
      _items[index] = _items[index].copyWith(isRead: true);
      _publish();
    }
  }

  void markAllAsRead() {
    if (_closed) return;
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        _items[i] = _items[i].copyWith(isRead: true);
      }
    }
    _publish();
  }

  void clearAll() {
    if (_closed) return;
    _items.clear();
    _publish();
  }

  void sendDemoNotification({
    String title = 'Cảnh báo ngân sách AI',
    String body =
        'Tài khoản OpenAI Codex đạt 85% hạn mức đã đặt cho tháng này.',
    String route = '/analytics',
  }) {
    final demoItem = NotificationItem(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      isRead: false,
      route: route,
      data: {'source': 'demo_generator'},
    );
    addNotification(demoItem);
  }

  void _publish() {
    if (_closed) return;
    _notificationsController.add(List.unmodifiable(_items));
  }

  Future<void> close() async {
    _closed = true;
    await _notificationsController.close();
    await _openedRouteController.close();
  }
}
