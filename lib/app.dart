import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'theme/app_theme.dart';
import 'viewmodels/ledger_viewmodel.dart';

class TokenLedgerApp extends ConsumerWidget {
  const TokenLedgerApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'TokenLedger',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: ref.watch(demoSessionProvider)
        ? const ShellScreen()
        : const LoginScreen(),
  );
}
