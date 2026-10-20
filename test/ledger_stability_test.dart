import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/ledger_validation.dart';
import 'package:token_ledger/utils/formatters.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

class PendingRepository extends MemoryRepository {
  Completer<void>? pending;
  int writes = 0;
  @override
  Future<void> save(LedgerData value) async {
    writes++;
    if (pending != null) await pending!.future;
    await super.save(value);
  }
}

void main() {
  final now = DateTime(2026, 10, 21, 10);
  late PendingRepository repository;
  late ProviderContainer container;
  late LedgerViewModel vm;
  UsageSession usage({
    String id = 'work',
    String title = 'Work',
    int? input,
    int? output,
    int? cost,
    String note = '',
    DateTime? date,
    String account = 'codex',
  }) => UsageSession(
    id: id,
    accountId: account,
    title: title,
    purpose: Purpose.code,
    occurredAt: date ?? now,
    inputTokens: input,
    outputTokens: output,
    costMicros: cost,
    note: note,
  );
  QuotaSnapshot quota({
    int percent = 10,
    DateTime? observed,
    DateTime? reset,
    String window = '5 giờ',
  }) => QuotaSnapshot(
    window: window,
    usedPercent: percent,
    observedAt: observed ?? now,
    resetAt: reset ?? now.add(const Duration(hours: 1)),
  );

  setUp(() async {
    repository = PendingRepository();
    container = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    await container.read(ledgerProvider.future);
    vm = container.read(ledgerProvider.notifier);
    repository.writes = 0;
  });
  tearDown(() => container.dispose());

  test(
    'B03 Unicode text limits count the same graphemes as Flutter fields',
    () async {
      final account = repository.data!.account('codex')!;
      final glyph = '👩🏽‍💻';
      await vm.saveAccount(account.copyWith(alias: glyph * 80));
      expect(repository.data!.account('codex')!.alias, glyph * 80);
      await expectLater(
        vm.saveAccount(account.copyWith(alias: glyph * 81)),
        throwsArgumentError,
      );
      await vm.saveUsage(usage(title: glyph * 120, note: 'a\u0301' * 1000));
      expect(repository.data!.sessions.last.note, 'a\u0301' * 1000);
    },
  );

  final invalidUsage = <String, UsageSession Function()>{
    'blank title': () => usage(title: '  '),
    'long title': () => usage(title: 'x' * 121),
    'long note': () => usage(note: 'x' * 1001),
    'input only': () => usage(input: 1),
    'output only': () => usage(output: 1),
    'negative input': () => usage(input: -1, output: 0),
    'negative output': () => usage(input: 0, output: -1),
    'oversized tokens': () =>
        usage(input: LedgerValidation.maxTokens + 1, output: 0),
    'negative cost': () => usage(cost: -1),
    'oversized cost': () => usage(cost: LedgerValidation.maxMoneyMicros + 1),
    'future time': () => usage(date: now.add(const Duration(microseconds: 1))),
    'before picker lower bound': () => usage(date: DateTime(2019, 12, 31)),
    'empty ID': () => usage(id: ''),
  };
  for (final entry in invalidUsage.entries) {
    test('B03 VM rejects ${entry.key} without publishing or saving', () async {
      await expectLater(vm.saveUsage(entry.value()), throwsArgumentError);
      expect(repository.writes, 0);
      expect(container.read(ledgerProvider).requireValue.sessions.length, 12);
    });
  }

  test('B03 null, measured zero and maximums retain their separate meaning after reload', () async {
    await vm.saveUsage(usage());
    await vm.saveUsage(usage(id: 'zero', input: 0, output: 0, cost: 0));
    await vm.saveUsage(
      usage(
        id: 'max',
        input: LedgerValidation.maxTokens,
        output: LedgerValidation.maxTokens,
        cost: LedgerValidation.maxMoneyMicros,
        note: 'x' * 1000,
        title: 'x' * 120,
      ),
    );
    container.invalidate(ledgerProvider);
    final data = await container.read(ledgerProvider.future);
    expect(data.sessions.firstWhere((s) => s.id == 'work').knownTokens, isNull);
    expect(data.sessions.firstWhere((s) => s.id == 'zero').knownTokens, 0);
    expect(data.sessions.firstWhere((s) => s.id == 'zero').costMicros, 0);
    expect(
      data.sessions.firstWhere((s) => s.id == 'max').costMicros,
      parseUsd('9999999.999999'),
    );
  });

  test(
    'B03 account bounds/required fields are enforced by VM without form',
    () async {
      final account = repository.data!.account('codex')!;
      for (final invalid in [
        account.copyWith(alias: ' '),
        account.copyWith(alias: 'x' * 81),
        account.copyWith(product: ''),
        account.copyWith(product: 'x' * 61),
        account.copyWith(plan: 'x' * 61),
        account.copyWith(provider: 'invented'),
        account.copyWith(budgetMicros: -1),
        account.copyWith(budgetMicros: LedgerValidation.maxMoneyMicros + 1),
      ]) {
        await expectLater(vm.saveAccount(invalid), throwsArgumentError);
      }
      expect(repository.writes, 0);
      await vm.saveAccount(
        account.copyWith(
          alias: 'x' * 80,
          product: 'x' * 60,
          plan: 'x' * 60,
          budgetMicros: 0,
        ),
      );
      await vm.saveAccount(
        repository.data!.account('codex')!.copyWith(clearBudget: true),
      );
      expect(repository.data!.account('codex')!.budgetMicros, isNull);
    },
  );

  test(
    'B03 quota update rejects all bad boundaries including saveAccount bypass',
    () async {
      final invalid = [
        quota(percent: -1),
        quota(percent: 101),
        quota(window: ''),
        quota(window: 'x' * 61),
        quota(reset: now),
        quota(observed: now.add(const Duration(minutes: 1))),
        quota(observed: now.add(const Duration(hours: 2))),
      ];
      for (final q in invalid) {
        await expectLater(vm.updateQuota('codex', q), throwsArgumentError);
        await expectLater(
          vm.saveAccount(repository.data!.account('codex')!.copyWith(quota: q)),
          throwsArgumentError,
        );
      }
      expect(repository.writes, 0);
      for (final percent in [0, 100]) {
        await vm.updateQuota('codex', quota(percent: percent));
        expect(
          repository.data!
              .account('codex')!
              .quotaWindows
              .singleWhere((q) => q.windowKey == quota().windowKey)
              .remainingPercent,
          100 - percent,
        );
      }
      await expectLater(vm.updateQuota('missing', quota()), throwsStateError);
    },
  );

  test('B03 parsers reject nondecimal paste and preserve every USD micro', () {
    for (final raw in ['0x10', '1e3', '1.5', '-0', '-1', 'NaN', '1000000001']) {
      expect(LedgerValidation.tokenInput(raw), isNotNull);
    }
    expect(LedgerValidation.tokenInput(' 0 '), isNull);
    expect(LedgerValidation.tokenInput(''), isNull);
    expect(LedgerValidation.percentInput(' 100 '), isNull);
    expect(LedgerValidation.percentInput('0x10'), isNotNull);
    expect(LedgerValidation.percentInput('101'), isNotNull);
    for (final raw in [
      '1e3',
      '-1',
      'NaN',
      'Infinity',
      '1,000.00',
      '10000000',
      '0.0000001',
    ]) {
      expect(() => parseUsd(raw), throwsFormatException);
    }
    for (final micros in [
      0,
      1,
      999999,
      1000000,
      1000001,
      LedgerValidation.maxMoneyMicros,
    ]) {
      expect(parseUsd(usdInput(micros)), micros);
    }
    expect(parseUsd(' 1,000001 '), 1000001);
    expect(money(1999995), r'$2.00');
    expect(money(9999999999999, decimals: 6), r'$9999999.999999');
    expect(money(-1, decimals: 6), '−\$0.000001');
  });

  test(
    'B04 archive history edit/delete/restore reconciles without moving account',
    () async {
      final original = repository.data!.sessions.firstWhere(
        (s) => s.accountId == 'codex',
      );
      await vm.archiveAccount('codex', true);
      await vm.saveUsage(
        UsageSession(
          id: original.id,
          accountId: original.accountId,
          title: 'Work',
          purpose: Purpose.code,
          occurredAt: now,
          costMicros: 7,
          dataSource: original.dataSource,
          isDemo: original.isDemo,
        ),
      );
      await expectLater(
        vm.saveUsage(usage(id: original.id, account: 'claude')),
        throwsStateError,
      );
      await expectLater(vm.saveUsage(usage(id: 'new')), throwsStateError);
      await expectLater(vm.deleteAccount('codex'), throwsStateError);
      await vm.deleteUsage(original.id);
      expect(
        repository.data!.sessions.where((s) => s.accountId == 'codex').length,
        3,
      );
      expect(repository.data!.account('codex')!.archived, isTrue);
      await vm.archiveAccount('codex', false);
      await vm.saveUsage(usage(id: 'new'));
      expect(
        repository.data!.sessions.where((s) => s.accountId == 'codex').length,
        4,
      );
    },
  );

  test(
    'B06 IDs stay unique at fixed/rolled-back clock and across VM recreation',
    () async {
      final ids = List.generate(1000, (_) => vm.newId()).toSet();
      expect(ids.length, 1000);
      expect(
        ids.every(
          (id) => RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ).hasMatch(id),
        ),
        isTrue,
      );
      await vm.saveUsage(usage(id: ids.first));
      final other = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(
            () => now.subtract(const Duration(days: 1)),
          ),
        ],
      );
      addTearDown(other.dispose);
      await other.read(ledgerProvider.future);
      final newIds = List.generate(
        1000,
        (_) => other.read(ledgerProvider.notifier).newId(),
      ).toSet();
      expect(ids.intersection(newIds), isEmpty);
    },
  );

  test('B06 overlapping save/delete/reset are rejected and retry merges latest snapshot', () async {
    repository.pending = Completer<void>();
    final first = vm.saveUsage(usage(id: 'first'));
    await expectLater(vm.saveUsage(usage(id: 'second')), throwsStateError);
    await expectLater(vm.deleteUsage('seed-0'), throwsStateError);
    await expectLater(vm.clearDemo(), throwsStateError);
    expect(repository.writes, 1);
    expect(container.read(ledgerProvider).requireValue.sessions.length, 12);
    repository.pending!.complete();
    await first;
    repository.pending = null;
    await vm.saveUsage(usage(id: 'second'));
    expect(repository.data!.sessions.length, 14);
    expect(repository.data!.sessions.where((s) => s.id == 'first').length, 1);
  });

  test('B06 failed pending save releases guard and retry same operation saves once', () async {
    repository.failWrites = true;
    await expectLater(vm.saveUsage(usage()), throwsStateError);
    expect(container.read(ledgerProvider).requireValue.sessions.length, 12);
    repository.failWrites = false;
    await vm.saveUsage(usage());
    await vm.saveUsage(usage());
    expect(repository.data!.sessions.length, 13);
  });

  test(
    'B06 reload during pending write waits and then loads committed data',
    () async {
      repository.pending = Completer<void>();
      final saved = vm.saveUsage(usage());
      container.invalidate(ledgerProvider);
      final loaded = container.read(ledgerProvider.future);
      repository.pending!.complete();
      await saved;
      expect((await loaded).sessions.length, 13);
      expect(container.read(ledgerProvider).requireValue.sessions.length, 13);
    },
  );

  test(
    'B06 disposed VM completes persistence without publishing into dead ref',
    () async {
      final disposable = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      await disposable.read(ledgerProvider.future);
      repository.pending = Completer<void>();
      final saved = disposable.read(ledgerProvider.notifier).saveUsage(usage());
      disposable.dispose();
      repository.pending!.complete();
      await saved;
      expect(repository.data!.sessions.length, 13);
    },
  );
}
