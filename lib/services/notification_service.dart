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
  final _subscriptions = <StreamSubscription<NotificationItem>>[];

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
    _subscriptions.add(
      _transport.onForegroundNotification.listen((item) {
        addNotification(item);
      }),
    );
    _subscriptions.add(
      _transport.onNotificationOpened.listen((item) {
        addNotification(item);
        if (item.route != null && item.route!.isNotEmpty) {
          _openedRouteController.add(item.route!);
        }
      }),
    );
  }

  Future<bool> requestPermission() async {
    if (_transport == null || _ownerId == null || _closed) return false;
    final owner = _ownerId;
    try {
      final granted = await _transport.requestPermission();
      if (_closed || owner != _ownerId) return false;
      _permissionGranted = granted;
      if (granted) {
        final token = await _transport.getToken();
        if (_closed || owner != _ownerId) return false;
        _deviceToken = token;
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<void> bindOwner(String? uid) async {
    if (_closed || uid == _ownerId) return;
    _ownerId = uid;
    _items.clear();
    _deviceToken = null;
    _permissionGranted = false;
    _publish();
    if (uid == null || _transport == null) return;
    final initial = await _transport.getInitialNotification();
    if (!_closed && _ownerId == uid && initial != null) {
      addNotification(initial);
    }
  }

  void addNotification(NotificationItem item) {
    if (_closed || _ownerId == null) return;
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

  void _publish() {
    if (_closed) return;
    _notificationsController.add(List.unmodifiable(_items));
  }

  Future<void> close() async {
    _closed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _notificationsController.close();
    await _openedRouteController.close();
  }
}
