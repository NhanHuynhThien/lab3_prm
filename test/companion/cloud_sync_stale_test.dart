import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/companion/services/auto_usage_rows.dart';
import 'package:token_ledger/companion/services/cloud_sync.dart';
import 'package:token_ledger/companion/services/companion_cloud.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);
  int at(DateTime d) => d.millisecondsSinceEpoch;
  AutoDoc doc(String id, String provider, DateTime when, {bool done = false}) =>
      (id: id, provider: provider, occurredMs: at(when), superseded: done);

  test('retires only rows a complete read no longer produces', () {
    final snapshot = {
      'providers': [
        {
          'id': 'codex',
          'activity': {'partial': false},
          autoUsageKey: [
            {'id': 'keep', 'provider': 'codex'},
          ],
        },
        // Partial read: a missing row may simply not have been read.
        {
          'id': 'claude',
          'activity': {'partial': true},
          autoUsageKey: <Object>[],
        },
      ],
    };
    final known = {
      for (final d in [
        doc('keep', 'codex', DateTime(2026, 11, 9)),
        doc('orphan', 'codex', DateTime(2026, 11, 9)),
        doc('done', 'codex', DateTime(2026, 11, 9), done: true),
        // Older than the read window: history, not an orphan.
        doc('old', 'codex', DateTime(2026, 10, 1)),
        doc('unread', 'claude', DateTime(2026, 11, 9)),
      ])
        d.id: d,
    };
    expect(CloudSync.staleRows(snapshot, known, now), ['orphan']);
  });

  test('a retire write targets only the flag of an existing row', () {
    final cloud = CompanionCloud(
      config: const CompanionFirebaseConfig(
        apiKey: 'k',
        authDomain: 'd',
        projectId: 'p',
        appId: 'a',
      ),
    );
    final w = cloud.supersedeWrite('U', 'x');
    expect((w['updateMask'] as Map)['fieldPaths'], ['superseded']);
    expect(w['currentDocument'], {'exists': true});
  });
}
