import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/companion/models/companion_state.dart';
import 'package:token_ledger/companion/services/activity_summary.dart';
import 'package:token_ledger/companion/services/cli_readers.dart';
import 'package:token_ledger/companion/services/desktop_platform.dart';
import 'package:token_ledger/companion/services/log_readers.dart';
import 'package:token_ledger/companion/services/model_usage.dart';
import 'package:token_ledger/companion/services/snapshot_collector.dart';

void main() {
  final now = DateTime.utc(2026, 11, 10, 12);

  test('purpose classification folds Vietnamese and breaks ties as other', () {
    expect(classifyPurpose('Sửa lỗi crash khi đăng nhập'), 'debug');
    expect(classifyPurpose('Thiết kế giao diện mới'), 'design');
    expect(classifyPurpose('test and review'), 'other');
    expect(classifyPurpose(null), 'other');
  });

  test('claude records keep the largest usage per message', () {
    String row(int output) => jsonEncode({
      'type': 'assistant',
      'timestamp': '2026-11-10T10:00:00Z',
      'sessionId': 's1',
      'message': {
        'id': 'm1',
        'model': 'claude-opus-5-5',
        'usage': {
          'input_tokens': 10,
          'cache_read_input_tokens': 5,
          'output_tokens': output,
        },
      },
    });
    final text = [
      jsonEncode({
        'type': 'user',
        'timestamp': '2026-11-10T09:59:00Z',
        'message': {'content': 'please fix this bug'},
      }),
      row(3),
      row(7),
    ].join('\n');
    final records = claudeModelRecords(text, now);
    expect(records, hasLength(1));
    expect(records.single.total, 22);
    expect(records.single.purpose, 'debug');
    final summary = activitySummary(records, now)!;
    expect(summary['totalTokens'], 22);
    expect(summary['cachedInputTokens'], 5);
    expect(summary['taskCount'], 1);
    expect(modelRows(records).single['model'], 'claude-opus-5-5');
  });

  test('codex cumulative token counts become per-event deltas', () {
    String count(int total) => jsonEncode({
      'type': 'event_msg',
      'timestamp': '2026-11-10T10:00:00Z',
      'payload': {
        'type': 'token_count',
        'info': {
          'total_token_usage': {
            'input_tokens': total - 1,
            'output_tokens': 1,
            'total_tokens': total,
          },
        },
      },
    });
    final text = [
      jsonEncode({
        'type': 'session_meta',
        'payload': {'id': 's'},
      }),
      jsonEncode({
        'type': 'turn_context',
        'payload': {'model': 'gpt-5'},
      }),
      count(100),
      count(150),
    ].join('\n');
    final records = codexModelRecords(text, now);
    expect(records.map((r) => r.total), [100, 50]);
  });

  test('gemini JSONL patches and rewinds are applied', () {
    final text = [
      jsonEncode({'type': 'gemini', 'id': 'a'}),
      jsonEncode({'type': 'gemini', 'id': 'b'}),
      jsonEncode({r'$rewindTo': 'a'}),
    ].join('\n');
    expect(geminiMessages(text).map((m) => m['id']), ['a']);
  });

  test('antigravity accepts only the read-only usage envelope', () {
    final ok = parseAntigravityUsage({
      'status': 'SUCCESS',
      'num_turns': 0,
      'command': {
        'name': 'usage',
        'data': {
          'groups': [
            {
              'name': 'Pro',
              'buckets': [
                {
                  'id': 'x',
                  'name': 'Model',
                  'window': '5h',
                  'remaining_fraction': 0.25,
                  'reset_time': '2026-11-10T15:00:00Z',
                },
              ],
            },
          ],
        },
      },
    }, now);
    expect((ok['windows'] as List).single['usedPercent'], 75);
    expect(
      () => parseAntigravityUsage({'status': 'SUCCESS', 'num_turns': 1}, now),
      throwsFormatException,
    );
  });

  test('snapshot digest ignores collection clocks only', () {
    final a = {
      'collectedAt': '1',
      'providers': [
        {'observedAt': 'x', 'totalTokens': 1},
      ],
    };
    final b = {
      'collectedAt': '2',
      'providers': [
        {'observedAt': 'y', 'totalTokens': 1},
      ],
    };
    final c = {
      'collectedAt': '2',
      'providers': [
        {'observedAt': 'y', 'totalTokens': 2},
      ],
    };
    expect(snapshotDigest(a), snapshotDigest(b));
    expect(snapshotDigest(a), isNot(snapshotDigest(c)));
  });

  test('preferences round-trip and drop unknown providers', () async {
    final dir = await Directory.systemTemp.createTemp('companion-prefs');
    addTearDown(() => dir.delete(recursive: true));
    final store = PreferencesStore(directory: dir.path);
    expect((await store.read()).consent, isFalse);
    await store.write(
      const CompanionPreferences(
        uid: 'u1',
        consent: true,
        providers: ['codex'],
      ),
    );
    final raw = jsonDecode(
      await File('${dir.path}/preferences.json').readAsString(),
    );
    raw['providers'] = ['codex', 'evil'];
    await File('${dir.path}/preferences.json').writeAsString(jsonEncode(raw));
    final read = await store.read();
    expect(read.uid, 'u1');
    expect(read.providers, ['codex']);
  });

  test('launch agent plist escapes the bundle path', () {
    final plist = LoginItemService.launchAgentPlist('/Apps/A&B <x>.app');
    expect(plist, contains('/Apps/A&amp;B &lt;x&gt;.app'));
    expect(plist, contains('--background'));
  });
}
