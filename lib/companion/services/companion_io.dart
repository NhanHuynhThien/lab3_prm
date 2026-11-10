import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

typedef Json = Map<String, Object?>;

const maxSafeInteger = 9007199254740991;
const dayMs = 86400000;

/// Largest CLI session log read. Long agent sessions reach tens of MB and
/// hold most of the tokens, so a low cap silently dropped real usage (a
/// 16MB cap hid ~300M Codex tokens on 10/11). Beyond this the read is
/// marked partial rather than risking memory on a desktop.
const maxLogBytes = 256 << 20;

String get homeDirectory =>
    Platform.environment['HOME'] ?? Directory.systemTemp.path;

/// Shared state folder with the Node bridge (Claude status line, account).
String get companionStateDir => '$homeDirectory/.local/share/tokenledger';

/// Finder and login launches have a minimal PATH. Add ordinary CLI install
/// locations without sourcing shell profiles or reading provider credentials.
Map<String, String> cliEnvironment() {
  final env = Map<String, String>.of(Platform.environment);
  final parts = <String>{
    ...(env['PATH'] ?? '').split(':').where((p) => p.isNotEmpty),
    '$homeDirectory/.local/bin',
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '$homeDirectory/.npm-global/bin',
    '/usr/bin',
    '/bin',
  };
  env['PATH'] = parts.join(':');
  return env;
}

/// Non-negative integer that JSON consumers can represent exactly.
int? safeCount(Object? value) {
  if (value is int) return value >= 0 && value <= maxSafeInteger ? value : null;
  if (value is double &&
      value.isFinite &&
      value == value.truncateToDouble() &&
      value >= 0 &&
      value <= maxSafeInteger) {
    return value.toInt();
  }
  return null;
}

bool isSafeSum(int a, int b) => a + b <= maxSafeInteger;

/// Milliseconds since epoch of an ISO timestamp, or null.
int? parseMs(Object? value) =>
    value is String ? DateTime.tryParse(value)?.millisecondsSinceEpoch : null;

/// ISO string with millisecond precision, like JavaScript's toISOString.
String isoMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

String isoNow(DateTime now) => isoMs(now.millisecondsSinceEpoch);

String opaqueId(Object? value) =>
    sha256.convert(utf8.encode('$value')).toString().substring(0, 16);

final _random = Random.secure();
String randomHex(int bytes) => List.generate(
  bytes,
  (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

/// Writes through a temp file so readers never see half a document.
Future<void> writeAtomic(String path, String text) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  final temp = File('${file.parent.path}/${randomHex(8)}.tmp');
  try {
    await temp.writeAsString(text, flush: true);
    await Process.run('/bin/chmod', ['600', temp.path]);
    await temp.rename(path);
  } finally {
    if (await temp.exists()) await temp.delete();
  }
}

/// Lists regular files below [root] without following symlinks. Missing
/// roots are silent; other failures and limits mark the result partial.
Future<({List<String> files, bool partial})> walkFiles(
  String root, {
  required bool Function(String name) accepts,
  required int maxDepth,
  bool descending = false,
  int limit = 500,
  bool deepIsPartial = true,
}) async {
  final files = <String>[];
  var partial = false;
  Future<void> walk(String dir, int depth) async {
    if (depth > maxDepth) {
      if (deepIsPartial) partial = true;
      return;
    }
    List<FileSystemEntity> entries;
    try {
      entries = await Directory(dir).list(followLinks: false).toList();
    } on PathNotFoundException {
      return;
    } catch (_) {
      partial = true;
      return;
    }
    String name(FileSystemEntity e) =>
        e.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
    entries.sort(
      (a, b) =>
          descending ? name(b).compareTo(name(a)) : name(a).compareTo(name(b)),
    );
    for (final entry in entries) {
      if (files.length >= limit) {
        partial = true;
        break;
      }
      if (entry is Link) continue;
      if (entry is Directory) {
        await walk(entry.path, depth + 1);
      } else if (entry is File && accepts(name(entry))) {
        files.add(entry.path);
      }
    }
  }

  await walk(root, 0);
  return (files: files, partial: partial);
}

/// Parses each JSON line; malformed lines are skipped like the CLI logs do.
Iterable<Json> jsonLines(String text) sync* {
  for (final line in const LineSplitter().convert(text)) {
    if (line.isEmpty) continue;
    Object? row;
    try {
      row = jsonDecode(line);
    } catch (_) {
      continue;
    }
    if (row is Map<String, Object?>) yield row;
  }
}

Json? asJson(Object? value) => value is Map<String, Object?> ? value : null;
