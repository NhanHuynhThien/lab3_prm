import 'dart:convert';

import 'package:token_ledger/models/ledger.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:token_ledger/services/ledger_repository.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'empty local storage does not create sample accounts or write a seed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(
            LocalLedgerRepository(prefs),
          ),
        ],
      );
      addTearDown(c.dispose);
      final ledger = await c.read(ledgerProvider.future);
      expect(ledger.accounts, isEmpty);
      expect(ledger.sessions, isEmpty);
      expect(prefs.get(LocalLedgerRepository.storageKey), isNull);
    },
  );
  test(
    'corrupt storage remains intact through load and explicit retry',
    () async {
      const original = '{broken';
      SharedPreferences.setMockInitialValues({
        LocalLedgerRepository.storageKey: original,
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalLedgerRepository(prefs);
      final c = ProviderContainer(
        overrides: [ledgerRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await expectLater(
        c.read(ledgerProvider.future),
        throwsA(isA<LedgerStorageException>()),
      );
      c.invalidate(ledgerProvider);
      await expectLater(
        c.read(ledgerProvider.future),
        throwsA(isA<LedgerStorageException>()),
      );
      expect(prefs.getString(LocalLedgerRepository.storageKey), original);
    },
  );
  test(
    'explicit repository recovery keeps a backup before replacing data',
    () async {
      SharedPreferences.setMockInitialValues({
        LocalLedgerRepository.storageKey: 'old-unreadable',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalLedgerRepository(prefs);
      await repo.replaceUnreadable(LedgerData(accounts: [], sessions: []));
      expect(
        jsonDecode(prefs.getString(LocalLedgerRepository.backupKey)!)['value'],
        'old-unreadable',
      );
      expect((await repo.load())!.accounts, isEmpty);
    },
  );
}
