import 'dart:async';

import 'package:flutter/foundation.dart';

abstract interface class CrashlyticsTransport {
  Future<void> enable(bool enabled);
  Future<void> setUserIdentifier(String? uid);
  Future<void> setCustomKey(String key, Object value);
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });
  void crash();
}

class CrashlyticsStatus {
  const CrashlyticsStatus({
    this.enabled = false,
    this.userId,
    this.lastRecordedError,
    this.errorCount = 0,
  });

  final bool enabled;
  final String? userId;
  final String? lastRecordedError;
  final int errorCount;
}

class CrashlyticsService {
  CrashlyticsService(this._transport);

  final CrashlyticsTransport? _transport;
  final _changes = StreamController<CrashlyticsStatus>.broadcast(sync: true);
  CrashlyticsStatus _status = const CrashlyticsStatus();
  bool _closed = false;
  int _ownerEpoch = 0;
  Future<void> _ownerBinding = Future.value();

  CrashlyticsStatus get current => _status;
  Stream<CrashlyticsStatus> get changes => _changes.stream;

  void _publish(CrashlyticsStatus status) {
    if (_closed) return;
    _status = status;
    _changes.add(status);
  }

  void setupErrorHooks() {
    if (_transport == null) return;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      recordFlutterError(details);
      originalOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordHandled(error, stack, 'uncaught_platform_dispatcher');
      return true;
    };
  }

  Future<void> bindOwner(String? uid) {
    if (_closed) return Future.value();
    final epoch = ++_ownerEpoch;
    _publish(const CrashlyticsStatus());
    _ownerBinding = _ownerBinding.catchError((_) {}).then((_) async {
      final transport = _transport;
      if (_closed || epoch != _ownerEpoch || transport == null) return;
      try {
        await transport.enable(uid != null);
        if (_closed || epoch != _ownerEpoch) return;
        await transport.setUserIdentifier(uid ?? '');
        await transport.setCustomKey('app_flavor', 'tokenledger');
        await transport.setCustomKey(
          'user_type',
          uid == null ? 'signed_out' : 'cloud_authenticated',
        );
        if (_closed || epoch != _ownerEpoch) return;
        _publish(CrashlyticsStatus(enabled: uid != null, userId: uid));
      } catch (_) {
        /* A configured SDK is not proof of an enabled/healthy transport. */
      }
    });
    return _ownerBinding;
  }

  Future<void> recordHandled(
    dynamic exception, [
    StackTrace? stack,
    String? reason,
  ]) async {
    if (_closed || _transport == null) return;
    final epoch = _ownerEpoch;
    final errStr = exception.toString();
    try {
      await _transport.setCustomKey(
        'last_error_time',
        DateTime.now().toUtc().toIso8601String(),
      );
      if (reason != null) {
        await _transport.setCustomKey('error_reason', reason);
      }
      await _transport.recordError(
        exception,
        stack ?? StackTrace.current,
        reason: reason ?? 'handled_business_error',
        fatal: false,
      );
    } catch (_) {
      return;
    }
    if (_closed || epoch != _ownerEpoch) return;
    _publish(
      CrashlyticsStatus(
        enabled: _status.enabled,
        userId: _status.userId,
        lastRecordedError: errStr,
        errorCount: _status.errorCount + 1,
      ),
    );
  }

  void recordFlutterError(FlutterErrorDetails details) {
    if (_closed || _transport == null) return;
    try {
      unawaited(
        _transport
            .recordError(
              details.exception,
              details.stack,
              reason: details.context?.toString(),
              fatal: false,
            )
            .catchError((_) {}),
      );
    } catch (_) {}
  }

  void triggerTestCrash() {
    _transport?.crash();
  }

  Future<void> close() async {
    _closed = true;
    await _changes.close();
  }
}
