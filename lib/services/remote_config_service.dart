import 'dart:async';

import '../models/product_features.dart';

class ConfigPayload {
  const ConfigPayload(this.values, this.sources);
  final Map<String, String> values, sources;
}

abstract interface class ConfigTransport {
  Future<void> prepare();
  ConfigPayload read();
  Future<void> fetch();
}

class RemoteConfigService {
  RemoteConfigService(this._transport, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  static const defaults = <String, Object>{
    'overview_recent_limit': 3,
    'budget_warning_percent': 80,
  };
  final ConfigTransport? _transport;
  final DateTime Function() _now;
  final _changes = StreamController<ProductConfig>.broadcast(sync: true);
  ProductConfig _current = const ProductConfig();
  Future<void>? _refresh;
  bool _ready = false, _closed = false;
  ProductConfig get current => _current;
  Stream<ProductConfig> get changes => Stream.multi((controller) {
    controller.add(current);
    final subscription = _changes.stream.listen(
      controller.add,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  void _publish(ProductConfig value) {
    if (_closed) return;
    _current = value;
    _changes.add(value);
  }

  ProductConfig _parse(ConfigPayload payload, {DateTime? fetchedAt}) {
    int value(String key, int fallback, int max) =>
        (int.tryParse(payload.values[key] ?? '') ?? fallback).clamp(1, max);
    String source(String key) =>
        int.tryParse(payload.values[key] ?? '') != null &&
            const {'remote', 'default'}.contains(payload.sources[key])
        ? payload.sources[key]!
        : 'default';
    return ProductConfig(
      recentLimit: value('overview_recent_limit', 3, 10),
      warningPercent: value('budget_warning_percent', 80, 100),
      recentSource: source('overview_recent_limit'),
      warningSource: source('budget_warning_percent'),
      fetchedAt: fetchedAt ?? current.fetchedAt,
    );
  }

  Future<void> refresh() {
    if (_closed || _transport == null) return Future.value();
    return _refresh ??= _load().whenComplete(() => _refresh = null);
  }

  Future<void> _load() async {
    _publish(current.busy());
    try {
      if (!_ready) {
        await _transport!.prepare().timeout(const Duration(seconds: 15));
        if (_closed) return;
        _ready = true;
        _publish(_parse(_transport.read()).busy());
      }
      await _transport!.fetch().timeout(const Duration(seconds: 20));
      if (!_closed) _publish(_parse(_transport.read(), fetchedAt: _now()));
    } catch (_) {
      _publish(current.failed());
    }
  }

  Future<void> close() async {
    _closed = true;
    await _changes.close();
  }
}
