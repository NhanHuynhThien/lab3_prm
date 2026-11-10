import 'dart:io';

import 'companion_io.dart';

/// Keeps the Firebase refresh token in the macOS login Keychain. The secret
/// reaches `security` through stdin so it never shows in the process list.
class KeychainStore {
  const KeychainStore({this.service = 'tokenledger-companion'});
  final String service;
  static const _security = '/usr/bin/security';
  static final _token = RegExp(r'^[A-Za-z0-9_-]{20,4096}$');

  Future<void> save(String value) async {
    // Refresh tokens are URL-safe; anything else is rejected first.
    if (!_token.hasMatch(value)) {
      throw const CompanionException('Phiên đăng nhập không hợp lệ.');
    }
    final child = await Process.start(_security, ['-i']);
    child.stdin.writeln(
      'add-generic-password -U -a $service -s $service -w "$value"',
    );
    await child.stdin.close();
    await Future.wait([child.stdout.drain<void>(), child.stderr.drain<void>()]);
    if (await child.exitCode != 0 || await load() != value) {
      throw const CompanionException('Không lưu được phiên đăng nhập.');
    }
  }

  Future<String?> load() async {
    try {
      final result = await Process.run(_security, [
        'find-generic-password',
        '-a',
        service,
        '-s',
        service,
        '-w',
      ]);
      if (result.exitCode != 0) return null;
      final value = (result.stdout as String).trim();
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete() async {
    try {
      await Process.run(_security, [
        'delete-generic-password',
        '-a',
        service,
        '-s',
        service,
      ]);
    } catch (_) {}
    for (final name in ['cloud-refresh-token', 'cloud-refresh-token.dpapi']) {
      final file = File('$companionStateDir/$name');
      if (await file.exists()) await file.delete();
    }
  }
}

/// User-facing error whose message is safe to show in the window.
class CompanionException implements Exception {
  const CompanionException(this.message);
  final String message;
  @override
  String toString() => message;
}
