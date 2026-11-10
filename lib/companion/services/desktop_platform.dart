import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/companion_state.dart';
import 'companion_io.dart';
import 'keychain_store.dart';

/// Preferences in the same folder the Electron build used, so consent and
/// the last sync survive the move to the Dart app.
class PreferencesStore {
  PreferencesStore({String? directory})
    : directory =
          directory ??
          '$homeDirectory/Library/Application Support/TokenLedger Companion';
  final String directory;

  Future<CompanionPreferences> read() async {
    try {
      final file = File('$directory/preferences.json');
      return CompanionPreferences.fromJson(
        jsonDecode(await file.readAsString()),
      );
    } catch (_) {
      return const CompanionPreferences();
    }
  }

  Future<void> write(CompanionPreferences value) async {
    await Directory(directory).create(recursive: true);
    await writeAtomic(
      '$directory/preferences.json',
      jsonEncode(value.toJson()),
    );
  }
}

/// Starts the app hidden at login through a per-user LaunchAgent.
class LoginItemService {
  LoginItemService({String? agentPath, String? executable})
    : agentPath =
          agentPath ?? '$homeDirectory/Library/LaunchAgents/$label.plist',
      executable = executable ?? Platform.resolvedExecutable;
  static const label = 'com.tokenledger.companion.desktop';
  final String agentPath;
  final String executable;

  /// Login items only make sense for an installed release build.
  bool get packaged => kReleaseMode;

  bool get enabled => File(agentPath).existsSync();

  Future<void> set(bool enabled) async {
    if (!packaged && enabled) {
      throw const CompanionException(
        'Mở bản ứng dụng đã đóng gói để bật khởi động cùng máy.',
      );
    }
    final file = File(agentPath);
    if (!enabled) {
      if (await file.exists()) await file.delete();
      return;
    }
    // Contents/MacOS/<exe> → the .app bundle opened through LaunchServices.
    final bundle = File(executable).parent.parent.parent.path;
    await file.parent.create(recursive: true);
    await file.writeAsString(launchAgentPlist(bundle));
  }

  static String launchAgentPlist(String bundle) {
    String xml(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>/usr/bin/open</string><string>-a</string><string>${xml(bundle)}</string><string>--args</string><string>--background</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
''';
  }
}

/// Removes the old Node CLI LaunchAgent once the desktop app is connected.
Future<void> retireLegacyService() async {
  const legacy = 'com.tokenledger.companion';
  final plist = '$homeDirectory/Library/LaunchAgents/$legacy.plist';
  try {
    final uid = (await Process.run('/usr/bin/id', ['-u'])).stdout.toString();
    await Process.run('/bin/launchctl', [
      'bootout',
      'gui/${uid.trim()}',
      plist,
    ]);
  } catch (_) {}
  final file = File(plist);
  if (await file.exists()) await file.delete();
}

/// Bridge to the native macOS shell: menu-bar item, hide-on-close, wake.
class DesktopShell {
  DesktopShell({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('tokenledger/companion_shell');
  final MethodChannel _channel;

  void listen(Future<void> Function(String action) onAction) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'action' && call.arguments is String) {
        await onAction(call.arguments as String);
      }
      return null;
    });
  }

  Future<void> updateMenu(CompanionState state) async {
    final connected = state.account != null && state.consent;
    try {
      await _channel.invokeMethod<void>('updateMenu', {
        'syncLabel': state.busy ? 'Đang đồng bộ…' : 'Đồng bộ ngay',
        'syncEnabled': connected && !state.busy,
        'toggleLabel': state.enabled ? 'Ngắt đồng bộ' : 'Đồng bộ',
        'toggleEnabled': connected,
      });
    } on MissingPluginException {
      // Widget tests and non-macOS hosts have no native shell.
    }
  }
}
