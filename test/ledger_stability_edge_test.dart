import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'support/ledger_stability_harness.dart';

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
