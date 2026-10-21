import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/services/ledger_repository.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'support/faulty_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 21, 10);
  final seed = createDemoSeed(now);
  const key = LocalLedgerRepository.storageKey;
  const backup = LocalLedgerRepository.backupKey;

  ProviderContainer owner(LedgerRepository repository) => ProviderContainer(
    overrides: [
      ledgerRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => now),
    ],
  );

  test(
    'B05 explicit recovery backs up original and only then saves seed',
    () async {
      const original = 'broken original JSON';
      SharedPreferences.setMockInitialValues({key: original});
      final prefs = await SharedPreferences.getInstance();
      final container = owner(LocalLedgerRepository(prefs));
      addTearDown(container.dispose);
      await expectLater(
        container.read(ledgerProvider.future),
        throwsA(isA<LedgerStorageException>()),
      );
      final vm = container.read(ledgerProvider.notifier);
      await expectLater(vm.clearDemo(), throwsStateError);
      await expectLater(vm.resetDemo(), throwsStateError);
      expect(prefs.getString(key), original);
      await vm.recoverDemo();
      expect(jsonDecode(prefs.getString(backup)!)['value'], original);
      expect(container.read(ledgerProvider).requireValue.sessions.length, 12);
      expect((await LocalLedgerRepository(prefs).load())!.sessions.length, 12);
      await expectLater(vm.recoverDemo(), throwsStateError);
    },
  );

  test('B05 recovery retains unsupported-version original exactly', () async {
    final raw = jsonEncode({
      'schemaVersion': 20,
      'future': [1, 2, 3],
    });
    final prefs = FaultyPreferences()..values[key] = raw;
    final repository = LocalLedgerRepository(prefs);
    await expectLater(
      repository.load(),
      throwsA(
        isA<LedgerStorageException>().having(
          (e) => e.problem,
          'problem',
          LedgerStorageProblem.unsupportedVersion,
        ),
      ),
    );
    await repository.replaceUnreadable(seed);
    expect(jsonDecode(prefs.values[backup] as String)['value'], raw);
  });

  test(
    'B05 read failure never becomes an empty successful load or seed',
    () async {
      final prefs = FaultyPreferences()
        ..values[key] = 'original'
        ..failReads = true;
      final container = owner(LocalLedgerRepository(prefs));
      addTearDown(container.dispose);
      await expectLater(
        container.read(ledgerProvider.future),
        throwsA(isA<LedgerStorageException>()),
      );
      await expectLater(
        container.read(ledgerProvider.notifier).recoverDemo(),
        throwsA(isA<LedgerStorageException>()),
      );
      expect(prefs.values, {key: 'original'});
      prefs.failReads = false;
      prefs.values[key] = jsonEncode(seed.toJson());
      container.invalidate(ledgerProvider);
      expect((await container.read(ledgerProvider.future)).sessions.length, 12);
    },
  );

  test(
    'B05 backup failure aborts recovery without overwriting original',
    () async {
      final prefs = FaultyPreferences()
        ..values[key] = '{broken'
        ..failKey = backup;
      final repository = LocalLedgerRepository(prefs);
      await expectLater(
        repository.replaceUnreadable(seed),
        throwsA(isA<LedgerStorageException>()),
      );
      expect(prefs.values, {key: '{broken'});
    },
  );

  test(
    'B05 replacement failure keeps backup/error and a successful retry works',
    () async {
      final prefs = FaultyPreferences()
        ..values[key] = '{broken'
        ..failKey = key;
      final container = owner(LocalLedgerRepository(prefs));
      addTearDown(container.dispose);
      await expectLater(
        container.read(ledgerProvider.future),
        throwsA(isA<LedgerStorageException>()),
      );
      await expectLater(
        container.read(ledgerProvider.notifier).recoverDemo(),
        throwsA(isA<LedgerStorageException>()),
      );
      expect(container.read(ledgerProvider).hasError, isTrue);
      expect(prefs.values[key], '{broken');
      expect(jsonDecode(prefs.values[backup] as String)['value'], '{broken');
      prefs.failKey = null;
      await container.read(ledgerProvider.notifier).recoverDemo();
      expect(container.read(ledgerProvider).hasValue, isTrue);
    },
  );

  test('B05 normal write false/exception retain last good VM data', () async {
    final prefs = FaultyPreferences()..values[key] = jsonEncode(seed.toJson());
    final container = owner(LocalLedgerRepository(prefs));
    addTearDown(container.dispose);
    await container.read(ledgerProvider.future);
    prefs.failKey = key;
    await expectLater(
      container.read(ledgerProvider.notifier).clearDemo(),
      throwsA(isA<LedgerStorageException>()),
    );
    expect(container.read(ledgerProvider).requireValue.sessions.length, 12);
    prefs.failKey = null;
    prefs.throwWrites = true;
    await expectLater(
      container.read(ledgerProvider.notifier).clearDemo(),
      throwsA(isA<LedgerStorageException>()),
    );
    expect(container.read(ledgerProvider).requireValue.sessions.length, 12);
  });

  test(
    'B05 plugin initialization failure is recoverable by explicit Retry',
    () async {
      final prefs = FaultyPreferences()
        ..values[key] = jsonEncode(seed.toJson());
      var fails = true;
      final repository = LocalLedgerRepository.open(
        openPreferences: () async {
          if (fails) throw StateError('plugin unavailable');
          return prefs;
        },
      );
      final container = owner(repository);
      addTearDown(container.dispose);
      await expectLater(
        container.read(ledgerProvider.future),
        throwsA(isA<LedgerStorageException>()),
      );
      expect(prefs.values[key], jsonEncode(seed.toJson()));
      fails = false;
      container.invalidate(ledgerProvider);
      expect((await container.read(ledgerProvider.future)).sessions.length, 12);
    },
  );

  test(
    'B05 UTC and measured zero survive persistence without becoming unknown',
    () async {
      final prefs = FaultyPreferences();
      final repository = LocalLedgerRepository(prefs);
      final data = seed.copyWith(
        sessions: [
          ...seed.sessions,
          UsageSession(
            id: 'utc-zero',
            accountId: 'codex',
            title: 'Recorded zero',
            purpose: Purpose.test,
            occurredAt: now.toUtc(),
            inputTokens: 0,
            outputTokens: 0,
            costMicros: 0,
          ),
        ],
      );
      await repository.save(data);
      final loaded = (await repository.load())!.sessions.last;
      expect(loaded.occurredAt.isUtc, isTrue);
      expect(loaded.occurredAt, now.toUtc());
      expect(loaded.knownTokens, 0);
      expect(loaded.costMicros, 0);
      expect((await repository.load())!.sessions[11].knownTokens, isNull);
    },
  );
}
