import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'companion/screens/companion_screen.dart';
import 'companion/services/browser_login.dart';
import 'companion/services/cloud_sync.dart';
import 'companion/services/companion_cloud.dart';
import 'companion/services/desktop_platform.dart';
import 'companion/services/usage_watcher.dart';
import 'companion/viewmodels/companion_controller.dart';
import 'theme/app_theme.dart';

/// TokenLedger Companion for macOS. Build with:
/// `flutter build macos -t lib/main_companion.dart`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final cloud = CompanionCloud(config: CompanionFirebaseConfig.fromOptions());
  final sync = CloudSync(cloud);
  final browser = BrowserLogin(cloud);
  const accounts = AccountFile();
  final preferences = PreferencesStore();
  final loginItem = LoginItemService();
  final dependencies = CompanionDependencies(
    readAccount: accounts.read,
    readPreferences: preferences.read,
    writePreferences: preferences.write,
    login: (cancel) => browser.login(cancel: cancel),
    logout: () async {
      await cloud.secrets.delete();
      await accounts.delete();
    },
    sync: (uid, {tokensOnly = false}) => sync(uid, tokensOnly: tokensOnly),
    setAutoStart: loginItem.set,
    readAutoStart: () => loginItem.enabled,
    retireLegacyService: retireLegacyService,
    watchChanges: (onChange) => UsageWatcher(onChange).close,
    packaged: loginItem.packaged,
  );
  final container = ProviderContainer(
    overrides: [companionDependenciesProvider.overrideWithValue(dependencies)],
  );
  final controller = container.read(companionControllerProvider.notifier);
  final shell = DesktopShell();
  shell.listen((action) async {
    final state = container.read(companionControllerProvider);
    switch (action) {
      case 'sync':
        await controller.sync(interactive: true);
      case 'toggle':
        await (state.enabled ? controller.pause() : controller.enable());
      case 'wake':
        if (state.enabled) await controller.sync();
      case 'quit':
        controller.close();
    }
  });
  container.listen(
    companionControllerProvider,
    (_, next) => unawaited(shell.updateMenu(next)),
    fireImmediately: true,
  );
  unawaited(
    controller.initialize().catchError((Object _) {
      controller.reportError(
        'Chưa khôi phục được đồng bộ. Hãy thử kết nối lại.',
      );
    }),
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        title: 'TokenLedger Companion',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const CompanionScreen(),
      ),
    ),
  );
}
