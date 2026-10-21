import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/ledger_validation.dart';
import 'package:token_ledger/utils/formatters.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'support/ledger_stability_harness.dart';

export 'support/ledger_stability_harness.dart' show PendingRepository;

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
  }) => createTestUsage(
    now,
    id: id,
    title: title,
    input: input,
    output: output,
    cost: cost,
    note: note,
    date: date,
    account: account,
  );

  QuotaSnapshot quota({
    int percent = 10,
    DateTime? observed,
    DateTime? reset,
    String window = '5 giờ',
  }) => createTestQuota(
    now,
    percent: percent,
    observed: observed,
    reset: reset,
    window: window,
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
      const glyph = '👩🏽‍💻';
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
}
