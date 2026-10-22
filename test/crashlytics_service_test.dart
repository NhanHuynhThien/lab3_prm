import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/services/crashlytics_service.dart';

class FakeCrashlyticsTransport implements CrashlyticsTransport {
  bool enabled = false;
  String? userId;
  final customKeys = <String, Object>{};
  final recordedErrors = <dynamic>[];
  bool crashed = false;

  @override
  Future<void> enable(bool val) async => enabled = val;

  @override
  Future<void> setUserIdentifier(String? uid) async => userId = uid;

  @override
  Future<void> setCustomKey(String key, Object value) async {
    customKeys[key] = value;
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    recordedErrors.add({'error': exception, 'reason': reason, 'fatal': fatal});
  }

  @override
  void crash() {
    crashed = true;
  }
}

void main() {
  group('CrashlyticsService', () {
    late FakeCrashlyticsTransport transport;
    late CrashlyticsService service;

    setUp(() {
      transport = FakeCrashlyticsTransport();
      service = CrashlyticsService(transport);
    });

    tearDown(() async {
      await service.close();
    });

    test('initial status is not enabled with zero errors', () {
      expect(service.current.enabled, isFalse);
      expect(service.current.errorCount, 0);
      expect(service.current.userId, isNull);
    });

    test('bindOwner sets user identity and custom keys', () async {
      await service.bindOwner('test_user_123');

      expect(transport.enabled, isTrue);
      expect(transport.userId, 'test_user_123');
      expect(transport.customKeys['app_flavor'], 'tokenledger');
      expect(transport.customKeys['user_type'], 'cloud_authenticated');
      expect(service.current.enabled, isTrue);
      expect(service.current.userId, 'test_user_123');
    });

    test('bindOwner(null) clears user identity for demo sandbox', () async {
      await service.bindOwner('test_user_123');
      await service.bindOwner(null);

      expect(transport.userId, '');
      expect(transport.customKeys['user_type'], 'demo_sandbox');
      expect(service.current.enabled, isFalse);
      expect(service.current.userId, isNull);
    });

    test(
      'recordHandled records non-fatal error and increments count',
      () async {
        final err = Exception('Database timeout');
        await service.recordHandled(err, StackTrace.current, 'test_context');

        expect(transport.recordedErrors, hasLength(1));
        expect(transport.recordedErrors.first['error'], err);
        expect(transport.recordedErrors.first['reason'], 'test_context');
        expect(transport.recordedErrors.first['fatal'], isFalse);
        expect(transport.customKeys['error_reason'], 'test_context');
        expect(transport.customKeys['last_error_time'], isNotNull);

        expect(service.current.errorCount, 1);
        expect(service.current.lastRecordedError, contains('Database timeout'));
      },
    );

    test('triggerTestCrash triggers transport crash', () {
      service.triggerTestCrash();
      expect(transport.crashed, isTrue);
    });
  });
}
