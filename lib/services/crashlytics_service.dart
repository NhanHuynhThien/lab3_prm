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

  Future<void> bindOwner(String? uid) async {
    if (_closed) return;
    try {
      if (uid != null) {
        await _transport?.enable(true);
        await _transport?.setUserIdentifier(uid);
        await _transport?.setCustomKey('app_flavor', 'tokenledger');
        await _transport?.setCustomKey('user_type', 'cloud_authenticated');
        _publish(
          CrashlyticsStatus(
            enabled: true,
            userId: uid,
            lastRecordedError: _status.lastRecordedError,
            errorCount: _status.errorCount,
          ),
        );
      } else {
        await _transport?.setUserIdentifier('');
        await _transport?.setCustomKey('user_type', 'signed_out');
        _publish(
          CrashlyticsStatus(
            enabled: false,
            userId: null,
            lastRecordedError: _status.lastRecordedError,
            errorCount: _status.errorCount,
          ),
        );
      }
    } catch (_) {
      // Best-effort; do not crash app on diagnostics failures
    }
  }

  Future<void> recordHandled(
    dynamic exception, [
    StackTrace? stack,
    String? reason,
  ]) async {
    if (_closed) return;
    final errStr = exception.toString();
    try {
      await _transport?.setCustomKey(
        'last_error_time',
        DateTime.now().toUtc().toIso8601String(),
      );
      if (reason != null) {
        await _transport?.setCustomKey('error_reason', reason);
      }
      await _transport?.recordError(
        exception,
        stack ?? StackTrace.current,
        reason: reason ?? 'handled_business_error',
        fatal: false,
      );
    } catch (_) {
      // Best-effort
    }
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
    if (_closed) return;
    try {
      _transport?.recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString(),
        fatal: false,
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
