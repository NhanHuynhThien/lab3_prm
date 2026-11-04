import 'dart:async';

import '../models/notification_item.dart';
import 'notification_contracts.dart';
export 'notification_contracts.dart';

class NotificationService {
  NotificationService(this._transport, {NotificationStore? backend})
    // ignore: prefer_initializing_formals
    : _backend = backend {
    _initListeners();
  }

  final NotificationTransport? _transport;
  final NotificationStore? _backend;
  bool registered = false;
  String? registrationError;
  bool inboxLoading = false;
  String? inboxError;
  String? _pendingRoute;
  bool _refreshStarted = false;
  bool get backendAvailable => _backend != null;
  final _notificationsController =
      StreamController<List<NotificationItem>>.broadcast(sync: true);
  final _openedRouteController = StreamController<String>.broadcast(sync: true);

  final List<NotificationItem> _items = [];
  String? _ownerId;
  String? _deviceToken;
  bool _permissionGranted = false;
  bool _closed = false;
  final _subscriptions = <StreamSubscription<dynamic>>[];

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
        openNotification(item);
      }),
    );
  }

  void _initRefreshListener() {
    if (_refreshStarted) return;
    final refresh = _transport;
    if (refresh is NotificationRefreshTransport) {
      _refreshStarted = true;
      _subscriptions.add(
        (refresh as NotificationRefreshTransport).onTokenRefresh.listen((
          token,
        ) {
          if (_permissionGranted && _ownerId != null) {
            unawaited(_register(_ownerId!, token));
          }
        }),
      );
    }
  }

  Future<void> _register(String uid, String token) async {
    if (_backend == null || uid != _ownerId || _closed) return;
    try {
      await _backend.register(uid, token);
      if (_closed || uid != _ownerId) return;
      _deviceToken = token;
      registered = true;
      registrationError = null;
    } catch (_) {
      if (_closed || uid != _ownerId) return;
      registered = false;
      registrationError =
          'Chưa đăng ký được thiết bị với backend. Hãy thử lại.';
    }
    _publish();
  }

  Future<void> refreshInbox() async {
    final uid = _ownerId;
    if (uid == null || _backend == null || _closed) return;
    inboxLoading = true;
    inboxError = null;
    _publish();
    try {
      final items = await _backend.inbox(uid);
      if (_closed || uid != _ownerId) return;
      for (final item in items) {
        addNotification(item);
      }
    } catch (_) {
      if (!_closed && uid == _ownerId) {
        inboxError = 'Chưa tải được hộp thư. Dữ liệu đã nhận vẫn được giữ lại.';
      }
    } finally {
      if (!_closed && uid == _ownerId) {
        inboxLoading = false;
        _publish();
      }
    }
  }

  /// Called before Firebase sign-out, while the old owner's token is valid.
  Future<void> detach() async {
    final uid = _ownerId;
    await bindOwner(null);
    if (uid != null && _backend != null) {
      try {
        await _backend.unregister(uid).timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
    final transport = _transport;
    if (transport is NotificationRefreshTransport) {
      try {
        await (transport as NotificationRefreshTransport).deleteToken().timeout(
          const Duration(seconds: 8),
        );
      } catch (_) {}
    }
    registered = false;
    await bindOwner(null);
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
        if (token != null) await _register(owner!, token);
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
    registered = false;
    registrationError = null;
    inboxLoading = false;
    inboxError = null;
    _pendingRoute = null;
    _publish();
    if (uid == null || _transport == null) return;
    _initRefreshListener();
    final initial = await _transport.getInitialNotification();
    if (!_closed && _ownerId == uid && initial != null) {
      addNotification(initial);
      openNotification(initial);
    }
    if (_closed || _ownerId != uid) return;
    await refreshInbox();
    final transport = _transport;
    if (transport is NotificationRefreshTransport) {
      try {
        final granted = await (transport as NotificationRefreshTransport)
            .hasPermission();
        if (_closed || _ownerId != uid) return;
        _permissionGranted = granted;
        if (granted) {
          final token = await _transport.getToken();
          if (token != null) await _register(uid, token);
        }
      } catch (_) {}
    }
  }

  void addNotification(NotificationItem item) {
    if (_closed || _ownerId == null) return;
    final owner = item.data['ownerUid'];
    if (owner != null && owner != _ownerId) return;
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
      final uid = _ownerId;
      if (uid != null &&
          _backend != null &&
          RegExp(r'^[0-9a-f-]{36}$').hasMatch(id)) {
        unawaited(_backend.read(uid, id).catchError((_) {}));
      }
    }
  }

  void markAllAsRead() {
    if (_closed) return;
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        markAsRead(_items[i].id);
      }
    }
    _publish();
  }

  void openNotification(NotificationItem item) {
    if (_ownerId == null || _closed) return;
    if (item.data['ownerUid'] != null && item.data['ownerUid'] != _ownerId) {
      return;
    }
    if (!{
      '/overview',
      '/accounts',
      '/analytics',
      '/profile',
    }.contains(item.route)) {
      return;
    }
    markAsRead(item.id);
    _pendingRoute = item.route;
    _openedRouteController.add(item.route!);
  }

  String? takePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
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
