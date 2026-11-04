import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_item.dart';
import '../firebase_options.dart';
import 'analytics_service.dart';
import 'crashlytics_service.dart';
import 'notification_service.dart';
import 'remote_config_service.dart';
import 'storage_service.dart';

class FirebaseAnalyticsTransport implements AnalyticsTransport {
  FirebaseAnalytics get _sdk => FirebaseAnalytics.instance;
  @override
  Future<void> enable(bool enabled) =>
      _sdk.setAnalyticsCollectionEnabled(enabled);
  @override
  Future<void> identify(String? uid) => _sdk.setUserId(id: uid);
  @override
  Future<void> event(String name, Map<String, Object> parameters) =>
      _sdk.logEvent(
        name: name,
        parameters: {
          ...parameters,
          if (const bool.fromEnvironment('FIREBASE_ANALYTICS_DEBUG'))
            'debug_mode': 1,
        },
      );
}

class FirebaseConfigTransport implements ConfigTransport {
  FirebaseRemoteConfig get _sdk => FirebaseRemoteConfig.instance;
  @override
  Future<void> prepare() async {
    await _sdk.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 12),
      ),
    );
    await _sdk.setDefaults(RemoteConfigService.defaults);
    await _sdk.ensureInitialized();
  }

  @override
  Future<void> fetch() async {
    await _sdk.fetchAndActivate();
  }

  @override
  ConfigPayload read() {
    final values = _sdk.getAll();
    return ConfigPayload(
      {
        for (final key in RemoteConfigService.defaults.keys)
          key: values[key]?.asString() ?? '',
      },
      {
        for (final key in RemoteConfigService.defaults.keys)
          key: values[key]?.source == ValueSource.valueRemote
              ? 'remote'
              : 'default',
      },
    );
  }
}

class FirebaseCrashlyticsTransport implements CrashlyticsTransport {
  FirebaseCrashlytics get _sdk => FirebaseCrashlytics.instance;

  @override
  Future<void> enable(bool enabled) =>
      _sdk.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> setUserIdentifier(String? uid) =>
      _sdk.setUserIdentifier(uid ?? '');

  @override
  Future<void> setCustomKey(String key, Object value) {
    if (value is String) return _sdk.setCustomKey(key, value);
    if (value is bool) return _sdk.setCustomKey(key, value);
    if (value is int) return _sdk.setCustomKey(key, value);
    if (value is double) return _sdk.setCustomKey(key, value);
    return _sdk.setCustomKey(key, value.toString());
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) => _sdk.recordError(exception, stack, reason: reason, fatal: fatal);

  @override
  void crash() => _sdk.crash();
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // The OS displays notification payloads. Never read a user's ledger here.
}

class FirebaseNotificationTransport
    implements NotificationTransport, NotificationRefreshTransport {
  FirebaseNotificationTransport() {
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }
  FirebaseMessaging get _sdk => FirebaseMessaging.instance;
  @override
  // HTTP v1 backend currently accepts registration tokens, not Installation IDs.
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _sdk.onTokenRefresh;
  @override
  Future<bool> hasPermission() async {
    final settings = await _sdk.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  // ignore: deprecated_member_use
  Future<void> deleteToken() => _sdk.deleteToken();

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _sdk.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      // ignore: deprecated_member_use
      // ignore: deprecated_member_use
      return await _sdk.getToken();
    } catch (_) {
      return null;
    }
  }

  NotificationItem _mapMessage(RemoteMessage msg) {
    return NotificationItem(
      id:
          msg.data['notificationId']?.toString() ??
          msg.messageId ??
          'fcm_${DateTime.now().millisecondsSinceEpoch}',
      title:
          msg.notification?.title ??
          msg.data['title']?.toString() ??
          'Thông báo mới',
      body: msg.notification?.body ?? msg.data['body']?.toString() ?? '',
      receivedAt: msg.sentTime ?? DateTime.now(),
      isRead: false,
      route: msg.data['route']?.toString(),
      data: msg.data.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  @override
  Stream<NotificationItem> get onForegroundNotification =>
      FirebaseMessaging.onMessage.map(_mapMessage);

  @override
  Stream<NotificationItem> get onNotificationOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_mapMessage);

  @override
  Future<NotificationItem?> getInitialNotification() async {
    try {
      final initial = await _sdk.getInitialMessage();
      return initial == null ? null : _mapMessage(initial);
    } catch (_) {
      return null;
    }
  }
}

class FirebaseStorageTransport implements StorageTransport {
  FirebaseStorage get _sdk => FirebaseStorage.instance;

  @override
  Future<String> uploadReport({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _sdk.ref('reports/$uid/$fileName');
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'ownerId': uid,
          'uploadedAt': DateTime.now().toUtc().toIso8601String(),
        },
      ),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        if (taskSnapshot.totalBytes > 0) {
          final progress =
              taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          onProgress(progress);
        }
      });
    }

    await uploadTask;
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteReport({
    required String uid,
    required String fileName,
  }) async {
    final ref = _sdk.ref('reports/$uid/$fileName');
    await ref.delete();
  }
}
