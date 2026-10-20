import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/ledger_repository.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

class MemoryRepository implements LedgerRepository {
  LedgerData? data;
  bool failWrites = false;
  @override
  Future<LedgerData?> load() async => data;
  @override
  Future<void> save(LedgerData value) async {
    if (failWrites) throw StateError('disk full');
    data = value;
  }
}

void main() {
  late ProviderContainer container;
  late MemoryRepository repository;
  setUp(() {
    repository = MemoryRepository();
    container = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 19, 10)),
      ],
    );
  });
  tearDown(() => container.dispose());
  test('create/update/delete usage persists and recalculates totals', () async {
    await container.read(ledgerProvider.future);
    final vm = container.read(ledgerProvider.notifier);
    final session = UsageSession(
      id: 'new',
      accountId: 'codex',
      title: 'Unit tests',
      purpose: Purpose.test,
      occurredAt: DateTime(2026, 10, 19),
      inputTokens: 8000,
      outputTokens: 2000,
      costMicros: 50000,
    );
    await vm.saveUsage(session);
    await vm.saveUsage(session);
    expect(container.read(ledgerProvider).requireValue.sessions.length, 13);
    expect(
      UsageCalculator.summarize(repository.data!.sessions).costMicros,
      12890000,
    );
    await vm.deleteUsage('new');
    expect(repository.data!.sessions.length, 12);
  });
  test('failed save does not publish a successful mutation', () async {
    await container.read(ledgerProvider.future);
    repository.failWrites = true;
    final vm = container.read(ledgerProvider.notifier);
    await expectLater(vm.clearDemo(), throwsStateError);
    expect(container.read(ledgerProvider).requireValue.accounts.length, 3);
  });
  test(
    'account with history cannot be deleted; archive preserves sessions',
    () async {
      await container.read(ledgerProvider.future);
      final vm = container.read(ledgerProvider.notifier);
      await expectLater(vm.deleteAccount('codex'), throwsStateError);
      await vm.archiveAccount('codex', true);
      expect(repository.data!.account('codex')!.archived, isTrue);
      expect(repository.data!.sessions.length, 12);
      await expectLater(
        vm.saveUsage(
          UsageSession(
            id: 'blocked',
            accountId: 'codex',
            title: 'Blocked',
            purpose: Purpose.code,
            occurredAt: DateTime(2026, 10, 19),
          ),
        ),
        throwsStateError,
      );
    },
  );
  test('empty account supports actual CRUD and survives reload', () async {
    await container.read(ledgerProvider.future);
    final vm = container.read(ledgerProvider.notifier);
    final account = AIAccount(
      id: 'empty',
      alias: 'Test',
      provider: 'OpenAI',
      product: 'Codex',
      billingMode: BillingMode.api,
      plan: '',
      createdAt: DateTime(2026, 10, 19),
    );
    await vm.saveAccount(account);
    await vm.saveAccount(account.copyWith(alias: 'Renamed'));
    container.invalidate(ledgerProvider);
    expect(
      (await container.read(ledgerProvider.future)).account('empty')!.alias,
      'Renamed',
    );
    await container.read(ledgerProvider.notifier).deleteAccount('empty');
    expect(repository.data!.account('empty'), isNull);
  });
}
