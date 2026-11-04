import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/analytics_service.dart';
import 'services/crashlytics_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/frame_audit_service.dart';
import 'services/firebase_product_services.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'services/firebase_platform_api.dart';
import 'services/platform_notification_store.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/product_features_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FrameAuditService.start();

  final crashlytics = CrashlyticsService(FirebaseCrashlyticsTransport());
  crashlytics.setupErrorHooks();
  final api = firebasePlatformApi();
  final notifications = NotificationService(
    FirebaseNotificationTransport(),
    backend: PlatformNotificationStore(api),
  );

  runApp(
    ProviderScope(
      overrides: [
        platformApiProvider.overrideWithValue(api),
        authServiceProvider.overrideWithValue(
          FirebaseAuthService(beforeSignOut: notifications.detach),
        ),
        analyticsServiceProvider.overrideWithValue(
          AnalyticsService(FirebaseAnalyticsTransport()),
        ),
        remoteConfigServiceProvider.overrideWithValue(
          RemoteConfigService(FirebaseConfigTransport()),
        ),
        crashlyticsServiceProvider.overrideWithValue(crashlytics),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const TokenLedgerApp(),
    ),
  );
}
