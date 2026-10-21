import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/firebase_auth_service.dart';
import 'services/ledger_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/ledger_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(FirebaseAuthService()),
        ledgerRepositoryProvider.overrideWithValue(
          LocalLedgerRepository.open(),
        ),
      ],
      child: const TokenLedgerApp(),
    ),
  );
}
