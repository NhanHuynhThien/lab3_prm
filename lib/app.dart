import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

class TokenLedgerApp extends ConsumerWidget {
  const TokenLedgerApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'TokenLedger',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    // Android's Material 3 overscroll stretches every card in the viewport.
    scrollBehavior: const MaterialScrollBehavior().copyWith(overscroll: false),
    // Browser paths/deep links always enter the guard before any data route.
    initialRoute: '/',
    home: const AuthGate(),
    onGenerateRoute: (_) =>
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
  );
}
