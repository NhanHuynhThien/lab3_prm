import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'companion_io.dart';

/// Reads quota through `codex app-server`. Deliberately exposes no
/// login/token/turn/write RPCs.
Future<Json> readCodex({
  String binary = 'codex',
  Duration timeout = const Duration(seconds: 8),
}) async {
  final child = await Process.start(binary, [
    'app-server',
  ], environment: cliEnvironment());
  final pending = <int, Completer<Object?>>{};
  var next = 0;
  void fail() {
    for (final task in pending.values) {
      if (!task.isCompleted) {
        task.completeError(StateError('Codex unavailable'));
      }
    }
    pending.clear();
  }

  unawaited(child.stderr.drain<void>());
  unawaited(child.exitCode.then((_) => fail()));
  final lines = child.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        Json? msg;
        try {
          msg = asJson(jsonDecode(line));
        } catch (_) {
          return;
        }
        final task = pending.remove(msg?['id']);
        if (task == null || task.isCompleted) return;
        msg!['error'] != null
            ? task.completeError(StateError('Codex RPC unavailable'))
            : task.complete(msg['result']);
      });

  Future<Json?> call(String method, [Object? params]) {
    final id = ++next;
    final task = pending[id] = Completer<Object?>();
    child.stdin.writeln(
      jsonEncode({'id': id, 'method': method, 'params': ?params}),
    );
    return task.future
        .timeout(timeout)
        .then(asJson)
        .whenComplete(() => pending.remove(id));
  }

  try {
    await call('initialize', {
      'clientInfo': {'name': 'tokenledger', 'version': '0.1.0'},
    });
    child.stdin.writeln('{"method":"initialized","params":{}}');
    final identity = await call('account/read', {'refreshToken': false});
    final account = asJson(identity?['account']);
    if (account == null || account['type'] != 'chatgpt') {
      return {
        'status': 'setup',
        'plan': null,
        'windows': [],
        'totalTokens': null,
      };
    }
    final quota = await call('account/rateLimits/read');
    // Older CLI versions may not expose usage/read. Quota remains usable.
    Json? usage;
    try {
      usage = await call('account/usage/read');
    } catch (_) {}
    return {
      'status': 'ready',
      'plan': account['planType'] is String ? account['planType'] : null,
      'windows': codexWindows(quota),
      'totalTokens': safeCount(asJson(usage?['summary'])?['lifetimeTokens']),
    };
  } finally {
    fail();
    await lines.cancel();
    try {
      await child.stdin.close();
    } catch (_) {}
    child.kill();
  }
}

List<Json> codexWindows(Json? quota) {
  final buckets =
      asJson(quota?['rateLimitsByLimitId']) ?? {'codex': quota?['rateLimits']};
  return [
    for (final MapEntry(key: id, :value) in buckets.entries)
      for (final key in const ['primary', 'secondary'])
        ?_codexWindow(id, asJson(asJson(value)?[key])),
  ];
}

Json? _codexWindow(String id, Json? w) {
  final used = w?['usedPercent'], reset = w?['resetsAt'];
  if (used is! num || !used.isFinite || used < 0 || used > 100) return null;
  if (reset is! num || !reset.isFinite) return null;
  return {
    'label': '$id · ${w!['windowDurationMins'] ?? '?'} phút',
    'usedPercent': used,
    'resetsAt': isoMs((reset * 1000).round()),
  };
}

Json _antigravityEmpty([String status = 'setup']) => {
  'id': 'antigravity',
  'status': status,
  'source': 'Antigravity · /usage chính thức',
  'coverage': 'Đăng nhập Antigravity CLI (agy) trên Mac để đọc quota. Lịch sử token IDE chưa được cung cấp.',
  'observedAt': null,
  'plan': null,
  'windows': <Object>[],
  'models': <Object>[],
  'totalTokens': null,
  'contextTokens': null,
  'estimatedCostMicros': null,
  'modelsCoverage':
      'Quota tài khoản và token từng model là hai chỉ số khác nhau.',
};

/// Accepts only the read-only `/usage` command envelope; never sends a prompt.
Json parseAntigravityUsage(Object? value, DateTime now) {
  final raw = asJson(value);
  final command = asJson(raw?['command']);
  final groups = asJson(command?['data'])?['groups'];
  if (raw?['status'] != 'SUCCESS' ||
      command?['name'] != 'usage' ||
      raw?['num_turns'] != 0 ||
      groups is! List) {
    throw const FormatException('Unsupported Antigravity usage envelope');
  }
  final windows = <Json>[];
  final seen = <String>{};
  final control = RegExp(r'[\x00-\x1f]');
  outer:
  for (final group in groups.map(asJson).whereType<Json>()) {
    final buckets = group['buckets'];
    for (final bucket in (buckets is List ? buckets : const []).map(asJson)) {
      final id = bucket?['id'], fraction = bucket?['remaining_fraction'];
      final reset = parseMs(bucket?['reset_time']);
      if (id is! String ||
          seen.contains(id) ||
          fraction is! num ||
          !fraction.isFinite ||
          fraction < 0 ||
          fraction > 1 ||
          reset == null) {
        continue;
      }
      final label = [
        group['name'],
        bucket!['name'],
        bucket['window'],
      ].whereType<String>().where((v) => v.isNotEmpty).join(' · ');
      if (label.isEmpty || label.length > 100 || control.hasMatch(label)) {
        continue;
      }
      seen.add(id);
      final name = group['name'];
      final window = bucket['window'];
      windows.add({
        'label': label,
        if (name is String && name.length <= 100) 'group': name,
        if (window == '5h' || window == 'weekly') 'window': window,
        'usedPercent': (1 - fraction) * 100,
        'resetsAt': isoMs(reset),
      });
      if (windows.length == 20) break outer;
    }
  }
  if (windows.isEmpty) {
    throw const FormatException('No supported quota buckets');
  }
  return {
    ..._antigravityEmpty('ready'),
    'observedAt': isoNow(now),
    'windows': windows,
    'coverage': 'Quota tài khoản từ Antigravity CLI chính thức. Không suy token IDE hoặc quota Gemini web từ các phần trăm này.',
  };
}

Future<Json> readAntigravity(DateTime now, {String? binary}) async {
  binary ??=
      Platform.environment['TOKENLEDGER_AGY_BIN'] ??
      '$homeDirectory/.local/bin/agy';
  try {
    final result = await Process.run(binary, [
      '--print',
      '/usage',
      '--output-format',
      'json',
    ], environment: cliEnvironment()).timeout(const Duration(seconds: 18));
    final stdout = result.stdout as String;
    if (result.exitCode != 0 || stdout.length > 256 * 1024) {
      return _antigravityEmpty('error');
    }
    return parseAntigravityUsage(jsonDecode(stdout), now);
  } on ProcessException catch (error) {
    return _antigravityEmpty(error.errorCode == 2 ? 'setup' : 'error');
  } catch (_) {
    return _antigravityEmpty('error');
  }
}
