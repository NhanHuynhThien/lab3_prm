import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/firebase_auth_service.dart';
import 'services/ledger_repository.dart';
import 'services/analytics_service.dart';
import 'services/remote_config_service.dart';
import 'services/firebase_product_services.dart';
import 'viewmodels/product_features_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/ledger_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        ledgerRepositoryProvider.overrideWithValue(
          LocalLedgerRepository.open(),
        ),
      ],
      child: const TokenLedgerApp(),
    ),
  );
}
