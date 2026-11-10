import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/companion/services/activity_summary.dart';
import 'package:token_ledger/companion/services/auto_usage_rows.dart';
import 'package:token_ledger/companion/services/companion_cloud.dart';
import 'package:token_ledger/companion/services/companion_io.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);
  String at(DateTime local) => isoMs(local.millisecondsSinceEpoch);
  UsageRecord rec(
    DateTime local, {
    Object task = 1,
    String session = 's1',
    int total = 100,
    int output = 20,
    String model = 'gpt-5',
    String purpose = 'debug',
  }) => UsageRecord(
    model: model,
    session: session,
    task: task,
    purpose: purpose,
    startedAt: at(local.subtract(const Duration(minutes: 5))),
    timestamp: at(local),
    input: total - output,
    output: output,
    total: total,
  );

  test('one row per task per local day; totals and model are kept', () {
    final rows = autoUsageRows('codex', [
      rec(DateTime(2026, 11, 9, 23, 50)),
      rec(DateTime(2026, 11, 10, 0, 10), total: 300, output: 50),
      rec(DateTime(2026, 11, 10, 0, 20), model: 'gpt-5-mini', total: 10),
      rec(DateTime(2026, 11, 10, 1), task: 2, purpose: 'test'),
    ], now);
    expect(rows, hasLength(3));
    final byDay = {
      for (final r in rows)
        if ((r['id'] as String).endsWith('20261110') &&
            r['detectedPurpose'] == 'debug')
          'today': r
        else if ((r['id'] as String).endsWith('20261109'))
          'yesterday': r,
    };
    final today = byDay['today']!;
    expect(today['inputTokens'], 310 - 70);
    expect(today['outputTokens'], 70);
    expect(today['model'], 'gpt-5');
    expect(byDay['yesterday']!['inputTokens'], 80);
    for (final r in rows) {
      expect(r['id'], matches(RegExp(r'^auto-codex-[0-9a-f]{16}-[0-9]{8}$')));
      expect(r.keys, isNot(contains('session')));
    }
    // Stable IDs: a later sync updates the same documents.
    expect(
      autoUsageRows('codex', [
        rec(DateTime(2026, 11, 10, 1), task: 2),
      ], now).single['id'],
      rows.firstWhere((r) => r['detectedPurpose'] == 'test')['id'],
    );
  });

  test('the partly-read oldest day and empty records are skipped', () {
    final rows = autoUsageRows('claude', [
      rec(DateTime(2026, 10, 11, 12)),
      rec(DateTime(2026, 10, 12, 12)),
      rec(DateTime(2026, 11, 10, 9), total: 0),
      rec(DateTime(2026, 11, 10, 9), session: ''),
    ], now);
    expect(rows.single['id'], endsWith('20261012'));
  });

  test('Gemini replies of one session share a row', () {
    final rows = autoUsageRows('google', [
      rec(DateTime(2026, 11, 10, 9), task: 'm1'),
      rec(DateTime(2026, 11, 10, 9, 5), task: 'm2'),
    ], now);
    expect(rows.single['inputTokens'], 160);
  });

  test('upload masks only Companion fields and strips rows from snapshot', () {
    final cloud = CompanionCloud(
      config: const CompanionFirebaseConfig(
        apiKey: 'k',
        authDomain: 'd',
        projectId: 'p',
        appId: 'a',
      ),
    );
    final row = autoUsageRows('codex', [
      rec(DateTime(2026, 11, 10, 9)),
    ], now).single;
    final write = cloud.autoUsageWrite('U', row);
    final mask = (write['updateMask'] as Map)['fieldPaths'] as List;
    expect(mask, isNot(contains('purpose')));
    expect(mask, isNot(contains('hidden')));
    expect(mask, isNot(contains('title')));
    expect(
      (write['update'] as Map)['name'],
      endsWith('/users/U/auto_usage/${row['id']}'),
    );
    final snapshot = {
      'providers': [
        {
          'id': 'codex',
          autoUsageKey: [row],
        },
      ],
    };
    expect(CompanionCloud.autoUsageOf(snapshot), [row]);
    final stripped = CompanionCloud.withoutAutoUsage(snapshot);
    expect((stripped['providers'] as List).single, {'id': 'codex'});
  });
}
