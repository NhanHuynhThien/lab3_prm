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
import 'services/storage_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/product_features_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FrameAuditService.start();

  final crashlytics = CrashlyticsService(FirebaseCrashlyticsTransport());
  crashlytics.setupErrorHooks();

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(FirebaseAuthService()),
        analyticsServiceProvider.overrideWithValue(
          AnalyticsService(FirebaseAnalyticsTransport()),
        ),
        remoteConfigServiceProvider.overrideWithValue(
          RemoteConfigService(FirebaseConfigTransport()),
        ),
        crashlyticsServiceProvider.overrideWithValue(crashlytics),
        notificationServiceProvider.overrideWithValue(
          NotificationService(FirebaseNotificationTransport()),
        ),
        storageServiceProvider.overrideWithValue(
          StorageService(FirebaseStorageTransport()),
        ),
      ],
      child: const TokenLedgerApp(),
    ),
  );
}
