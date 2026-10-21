import 'dart:async';

import '../models/product_features.dart';

abstract interface class AnalyticsTransport {
  Future<void> enable(bool enabled);
  Future<void> identify(String? uid);
  Future<void> event(String name, Map<String, Object> parameters);
}

/// No arbitrary user strings cross the telemetry boundary.
class ProductEvent {
  ProductEvent._(this.name, Map<String, Object> parameters)
    : parameters = Map.unmodifiable(parameters);
  final String name;
  final Map<String, Object> parameters;

  static ProductEvent? screen(String screen) =>
      const {'overview', 'accounts', 'analytics', 'profile'}.contains(screen)
      ? ProductEvent._('screen_view', {'screen_name': screen})
      : null;

  static ProductEvent? detail(String type) =>
      const {'account', 'usage'}.contains(type)
      ? ProductEvent._('view_$type', {'detail_type': type})
      : null;

  static ProductEvent? mutation(String entity, String action) {
    if (!const {'account', 'usage', 'quota'}.contains(entity) ||
        !const {'create', 'update', 'delete'}.contains(action)) {
      return null;
    }
    return ProductEvent._(
      '${entity}_${action == 'delete' ? 'deleted' : 'saved'}',
      {'action': action},
    );
  }

  static ProductEvent refresh(bool success) => ProductEvent._(
    'remote_config_refresh',
    {'outcome': success ? 'success' : 'failure'},
  );
}

/// One app-scoped instance, injected; never a global mutable singleton.
/// All SDK identity/event operations are serialized. Failures are isolated from
/// business saves, and stale queued events cannot be attributed to a new owner.
class AnalyticsService {
  AnalyticsService(this._transport);
  final AnalyticsTransport? _transport;
  final _changes = StreamController<AnalyticsStatus>.broadcast(sync: true);
  final _seen = <String>{};
  AnalyticsStatus _status = const AnalyticsStatus();
  Future<void> _tail = Future.value();
  String? _desired, _active;
  int _epoch = 0;
  bool _closed = false;
  AnalyticsStatus get current => _status;
  Stream<AnalyticsStatus> get changes => Stream.multi((controller) {
    controller.add(current);
    final subscription = _changes.stream.listen(
      controller.add,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  void _publish(AnalyticsStatus value) {
    if (_closed) return;
    _status = value;
    _changes.add(value);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _tail.then((_) async {
      if (_closed) return;
      try {
        await action();
      } catch (_) {
        _publish(
          const AnalyticsStatus(
            error: 'Analytics chưa nhận được thao tác. Dữ liệu công việc vẫn được lưu độc lập.',
          ),
        );
      }
    });
    _tail = next;
    return next;
  }

  Future<void> setOwner(String? uid) {
    if (_desired == uid &&
        (current.enabled ||
            uid == null && _active == null && current.error == null)) {
      return _tail;
    }
    _desired = uid;
    final epoch = ++_epoch;
    _seen.clear();
    _publish(const AnalyticsStatus());
    if (_transport == null) return Future.value();
    return _enqueue(() async {
      if (_active != null) {
        try {
          await _transport.event('logout', {'reason': 'auth_state'});
        } finally {
          try {
            await _transport.enable(false);
          } finally {
            await _transport.identify(null);
            _active = null;
          }
        }
      }
      if (uid == null || epoch != _epoch) return;
      await _transport.enable(false);
      await _transport.identify(uid);
      if (epoch != _epoch) {
        await _transport.identify(null);
        return;
      }
      await _transport.enable(true);
      _active = uid;
      await _transport.event('login', {
        'method': 'google',
        'entry': 'auth_state',
      });
      if (epoch == _epoch) {
        _publish(const AnalyticsStatus(enabled: true, lastEvent: 'login'));
      }
    });
  }

  Future<void> record(ProductEvent? event, {String? operationId}) {
    final uid = _desired;
    if (event == null || uid == null || _transport == null || _closed) {
      return Future.value();
    }
    final epoch = _epoch;
    final dedupe = operationId == null ? null : '${event.name}/$operationId';
    if (dedupe != null && !_seen.add(dedupe)) return Future.value();
    if (_seen.length > 512) _seen.remove(_seen.first);
    return _enqueue(() async {
      if (epoch != _epoch || uid != _active) return;
      await _transport.event(event.name, event.parameters);
      if (epoch == _epoch) {
        _publish(AnalyticsStatus(enabled: true, lastEvent: event.name));
      }
    });
  }

  Future<void> close() async {
    await setOwner(null);
    _closed = true;
    await _changes.close();
  }
}
