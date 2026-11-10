import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'cli_readers.dart';
import 'companion_io.dart';
import 'log_readers.dart';
import 'local_model_usage.dart';

/// Builds the sanitised `provider_snapshots/latest` payload the phone reads.
class SnapshotCollector {
  const SnapshotCollector();

  /// Full refresh, including provider quota CLIs.
  Future<Json> collect() async {
    final now = DateTime.now();
    final codex = _readCodexRow(now);
    final results = await Future.wait([
      codex,
      readClaude(),
      readGemini(now),
      readAntigravity(now),
      localModelUsage('codex', now),
      localModelUsage('claude', now),
    ]);
    return {
      'schemaVersion': 1,
      'collectedAt': isoNow(DateTime.now()),
      'providers': [
        withLocalUsage(results[0], results[4], now),
        withLocalUsage(results[1], results[5], now),
        results[2],
        results[3],
      ],
    };
  }

  /// Token-only refresh from local logs, keeping the last observed quota.
  /// Provider quota CLIs stay on the slower periodic refresh.
  Future<Json> collectTokens(Json previous) async {
    final now = DateTime.now();
    final results = await Future.wait([
      localModelUsage('codex', now),
      localModelUsage('claude', now),
      readGemini(now),
      readClaude(),
    ]);
    final [codexModels, claudeModels, google, claudeContext] = results;
    final providers = [
      for (final provider in (previous['providers'] as List).cast<Json>())
        if (provider['id'] == 'google')
          google
        else if (provider['id'] != 'codex' && provider['id'] != 'claude')
          provider
        else
          withLocalUsage(
            _tokenBase(provider, claudeContext),
            provider['id'] == 'codex' ? codexModels : claudeModels,
            now,
          ),
    ];
    return {...previous, 'collectedAt': isoNow(now), 'providers': providers};
  }

  Json _tokenBase(Json provider, Json claudeContext) {
    var base = provider;
    if (provider['source'] == 'Phiên lưu trên máy') {
      base = {
        ...provider,
        'status': 'setup',
        'totalTokens': null,
        'observedAt': null,
      };
    }
    if (provider['id'] == 'claude' && claudeContext['status'] == 'ready') {
      base = claudeContext;
    }
    return base;
  }

  Future<Json> _readCodexRow(DateTime now) async {
    try {
      final result = await readCodex(
        binary: const String.fromEnvironment(
          'TOKENLEDGER_CODEX_BIN',
          defaultValue: 'codex',
        ),
      );
      return {
        'id': 'codex',
        'source': 'Codex App Server',
        'coverage': 'Quota tài khoản CLI hiện tại; token lifetime nếu CLI hỗ trợ. Không phải phí đã charge.',
        'observedAt': isoNow(now),
        'contextTokens': null,
        'estimatedCostMicros': null,
        'billedCostMicros': null,
        'subscriptionFeeMicros': null,
        ...result,
      };
    } catch (_) {
      return {
        'id': 'codex',
        'status': 'error',
        'plan': null,
        'windows': <Object>[],
        'source': 'Codex App Server',
        'coverage':
            'Cần Codex CLI đã đăng nhập; cập nhật CLI nếu RPC chưa hỗ trợ.',
        'observedAt': null,
        'totalTokens': null,
        'contextTokens': null,
        'estimatedCostMicros': null,
        'subscriptionFeeMicros': null,
        'billedCostMicros': null,
      };
    }
  }
}

/// Quota needs the CLI/status line, but local session logs alone already
/// give real token counts; show those instead of hiding the source.
Json withLocalUsage(Json row, Json usage, DateTime now) {
  final merged = {...row, ...usage};
  final total = asJson(usage['activity'])?['totalTokens'];
  final models = usage['models'];
  if (row['status'] == 'ready' ||
      models is! List ||
      models.isEmpty ||
      total == null) {
    return merged;
  }
  return {
    ...merged,
    'status': 'ready',
    'totalTokens': total,
    'observedAt': isoNow(now),
    'source': 'Phiên lưu trên máy',
    'coverage': '${usage['modelsCoverage']} Chưa đọc được quota tài khoản.',
  };
}

const _clockKeys = {'collectedAt', 'observedAt', 'periodStart', 'periodEnd'};

Object? _withoutClocks(Object? value) => switch (value) {
  Map() => {
    for (final e in value.entries)
      if (!_clockKeys.contains(e.key)) e.key: _withoutClocks(e.value),
  },
  List() => value.map(_withoutClocks).toList(),
  _ => value,
};

/// Collection clocks and the sliding window advance on every read. Actual
/// usage timestamps, quota reset times and aggregate values remain hashed.
String snapshotDigest(Json snapshot) => sha256
    .convert(utf8.encode(jsonEncode(_withoutClocks(snapshot))))
    .toString();
