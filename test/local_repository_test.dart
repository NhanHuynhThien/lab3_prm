import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/demo_seed.dart';

import 'package:token_ledger/services/ledger_repository.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

export 'support/faulty_preferences.dart' show FaultyPreferences;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 21, 10);
  final seed = createDemoSeed(now);
  const key = LocalLedgerRepository.storageKey;
  const backup = LocalLedgerRepository.backupKey;
  Map<String, dynamic> jsonCopy() =>
      jsonDecode(jsonEncode(seed.toJson())) as Map<String, dynamic>;
  ProviderContainer owner(LedgerRepository repository) => ProviderContainer(
    overrides: [
      ledgerRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => now),
    ],
  );

  final badBlobs = <String, Object Function()>{
    'invalid JSON': () => '{oops',
    'wrong preference type': () => 123,
    'wrong root': () => '[]',
    'missing schema': () {
      final j = jsonCopy()..remove('schemaVersion');
      return jsonEncode(j);
    },
    'future schema': () => jsonEncode(jsonCopy()..['schemaVersion'] = 3),
    'fractional schema': () => jsonEncode(jsonCopy()..['schemaVersion'] = 1.5),
    'wrong field type': () {
      final j = jsonCopy();
      j['sessions'][0]['costMicros'] = '1';
      return jsonEncode(j);
    },
    'invalid enum': () {
      final j = jsonCopy();
      j['sessions'][0]['purpose'] = 'invented';
      return jsonEncode(j);
    },
    'negative cost': () {
      final j = jsonCopy();
      j['sessions'][0]['costMicros'] = -1;
      return jsonEncode(j);
    },
    'one sided tokens': () {
      final j = jsonCopy();
      j['sessions'][0]['inputTokens'] = null;
      return jsonEncode(j);
    },
    'oversized number': () {
      final j = jsonCopy();
      j['sessions'][0]['outputTokens'] = 1000000001;
      return jsonEncode(j);
    },
    'duplicate usage ID': () {
      final j = jsonCopy();
      j['sessions'][1]['id'] = j['sessions'][0]['id'];
      return jsonEncode(j);
    },
    'duplicate account ID': () {
      final j = jsonCopy();
      j['accounts'][1]['id'] = j['accounts'][0]['id'];
      return jsonEncode(j);
    },
    'orphan usage': () {
      final j = jsonCopy();
      j['sessions'][0]['accountId'] = 'missing';
      return jsonEncode(j);
    },
    'nonexistent calendar date': () {
      final j = jsonCopy();
      j['sessions'][0]['occurredAt'] = '2026-02-30T10:00:00.000';
      return jsonEncode(j);
    },
    'invalid hour': () {
      final j = jsonCopy();
      j['sessions'][0]['occurredAt'] = '2026-10-21T25:00:00.000';
      return jsonEncode(j);
    },
    'invalid quota percent': () {
      final j = jsonCopy();
      j['accounts'][0]['quotaWindows'][0]['usedPercent'] = 101;
      return jsonEncode(j);
    },
    'invalid quota times': () {
      final j = jsonCopy();
      j['accounts'][0]['quotaWindows'][0]['resetAt'] =
          j['accounts'][0]['quotaWindows'][0]['observedAt'];
      return jsonEncode(j);
    },
  };
  for (final entry in badBlobs.entries) {
    test(
      'B05 ${entry.key}: load/retry preserve original without seed writes',
      () async {
        final original = entry.value();
        SharedPreferences.setMockInitialValues({key: original});
        final prefs = await SharedPreferences.getInstance();
        final repository = LocalLedgerRepository(prefs);
        final container = owner(repository);
        addTearDown(container.dispose);
        for (var retry = 0; retry < 2; retry++) {
          await expectLater(
            container.read(ledgerProvider.future),
            throwsA(isA<LedgerStorageException>()),
          );
          expect(prefs.get(key), original);
          expect(prefs.get(backup), isNull);
          container.invalidate(ledgerProvider);
        }
      },
    );
  }

  test('schema2 round trip preserves unknown/zero/UTC/stale', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = LocalLedgerRepository(prefs);
    await repository.save(seed);
    final loaded = await repository.load();
    expect(loaded!.toJson(), seed.toJson());
    expect(jsonDecode(prefs.getString(key)!)['schemaVersion'], 2);
    final stale = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(
          () => now.add(const Duration(days: 40)),
        ),
      ],
    );
    addTearDown(stale.dispose);
    final old = await stale.read(ledgerProvider.future);
    expect(
      old.accounts.first.quota!.isStale(now.add(const Duration(days: 40))),
      isTrue,
    );
    expect(old.sessions.last.costMicros, isNull);
    final backward = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(
          () => now.subtract(const Duration(days: 1)),
        ),
      ],
    );
    addTearDown(backward.dispose);
    expect((await backward.read(ledgerProvider.future)).sessions.length, 12);
  });
}
