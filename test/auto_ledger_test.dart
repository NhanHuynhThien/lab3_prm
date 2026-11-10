import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/auto_usage.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/models/provider_usage.dart';
import 'package:token_ledger/services/auto_ledger.dart';
import 'package:token_ledger/services/auto_usage_store.dart';
import 'package:token_ledger/services/firestore_ledger_repository.dart';
import 'package:token_ledger/services/ledger_validation.dart';
import 'package:token_ledger/viewmodels/auto_usage_viewmodel.dart';
import 'package:token_ledger/viewmodels/cloud_ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'support/ledger_cloud_fake.dart';

const _id = 'auto-codex-0123456789abcdef-20261020';
final _now = DateTime.utc(2026, 10, 21, 9);

AutoUsageEntry _entry({
  String id = _id,
  bool hidden = false,
  Purpose? purpose,
  String? title,
}) => AutoUsageEntry(
  id: id,
  provider: 'codex',
  detectedPurpose: Purpose.debug,
  inputTokens: 1200,
  outputTokens: 300,
  occurredAt: _now.subtract(const Duration(hours: 1)),
  startedAt: _now.subtract(const Duration(hours: 2)),
  modelId: 'gpt-5',
  purpose: purpose,
  title: title,
  hidden: hidden,
);

ProviderUsage _codexSource() => ProviderUsage(
  id: 'codex',
  status: 'ready',
  source: 'Codex App Server',
  coverage: '',
  observedAt: _now,
  plan: 'plus',
  windows: [
    ProviderQuota('codex · 300 phút', 42.6, _now.add(const Duration(hours: 3))),
    // Already reset before it was observed: not a valid ledger window.
    ProviderQuota('stale', 10, _now.subtract(const Duration(hours: 1))),
  ],
);

class _FakeAutoStore implements AutoUsageStore {
  final rows = StreamController<List<AutoUsageEntry>>.broadcast();
  final edits = <String, AutoUsageEdit>{};
  final hidden = <String>[];
  @override
  Stream<List<AutoUsageEntry>> watch(String uid) => rows.stream;
  @override
  Future<void> edit(String uid, String id, AutoUsageEdit edit) async =>
      edits[id] = edit;
  @override
  Future<void> hide(String uid, String id) async => hidden.add(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AutoUsageEntry', () {
    test('parses a Companion row and keeps user edits separate', () {
      final e = AutoUsageEntry.tryParse(_id, {
        'provider': 'codex',
        'detectedPurpose': 'debug',
        'model': 'gpt-5',
        'inputTokens': 10,
        'outputTokens': 5,
        'occurredAt': _now,
        'purpose': 'review',
        'title': '',
      })!;
      final s = e.toSession();
      expect(s.purpose, Purpose.review);
      expect(s.title, 'Codex CLI · Code review');
      expect(s.knownTokens, 15);
      expect(s.costMicros, isNull);
      expect(s.dataSource, DataSource.companion);
      expect(s.accountId, 'auto-codex');
    });

    test('rejects rows this version cannot show', () {
      final base = {
        'provider': 'codex',
        'inputTokens': 1,
        'outputTokens': 1,
        'occurredAt': _now,
      };
      expect(AutoUsageEntry.tryParse('manual-id', base), isNull);
      expect(
        AutoUsageEntry.tryParse(_id, {...base, 'provider': 'other'}),
        isNull,
      );
      expect(
        AutoUsageEntry.tryParse(_id, {...base, 'inputTokens': -1}),
        isNull,
      );
      // Retired by the Companion: never counted.
      expect(
        AutoUsageEntry.tryParse(_id, {...base, 'superseded': true}),
        isNull,
      );
      expect(
        AutoUsageEntry.tryParse(_id, {...base, 'occurredAt': 'x'}),
        isNull,
      );
    });
  });

  group('AutoLedger.merge', () {
    final manual = LedgerData(
      accounts: [
        AIAccount(
          id: 'a',
          alias: 'API',
          provider: 'OpenAI',
          product: 'API',
          billingMode: BillingMode.api,
          plan: '',
          createdAt: _now.subtract(const Duration(days: 3)),
        ),
      ],
      sessions: const [],
    );

    test('adds one valid account per provider and hides hidden rows', () {
      final merged = AutoLedger.merge(
        manual,
        [_entry(), _entry(id: '${_id}x', hidden: true)],
        [_codexSource()],
      );
      LedgerValidation.snapshot(merged);
      expect(merged.accounts.map((a) => a.id), ['a', 'auto-codex']);
      final auto = merged.account('auto-codex')!;
      expect(auto.dataSource, DataSource.companion);
      expect(auto.plan, 'plus');
      expect(auto.quotaWindows.single.usedPercent, 43);
      expect(merged.sessions.single.id, _id);
      expect(DataScope.manual.includes(merged.sessions.single), isTrue);
      expect(DataScope.manual.includesAccount(auto, merged.sessions), isTrue);
    });

    test('a source with only quota still gets an account', () {
      final merged = AutoLedger.merge(manual, const [], [_codexSource()]);
      expect(merged.account('auto-codex')!.quotaWindows, hasLength(1));
      expect(acceptsManualUsage(merged.account('auto-codex')!), isFalse);
      expect(acceptsManualUsage(merged.account('a')!), isTrue);
    });
  });

  group('cloud ledger with Companion rows', () {
    late LedgerCloudFake store;
    late ProviderContainer container;
    late _FakeAutoStore auto;
    Future<void> flush() =>
        Future<void>.delayed(const Duration(milliseconds: 10));

    setUp(() async {
      store = LedgerCloudFake();
      auto = _FakeAutoStore();
      final repo = FirestoreLedgerRepository(
        ownerId: 'A',
        store: store,
        now: () => _now,
      );
      container = ProviderContainer(
        overrides: [
          cloudOwnerProvider.overrideWithValue('A'),
          cloudRepositoryFactoryProvider.overrideWithValue(() => repo),
          ledgerProvider.overrideWith(CloudLedgerViewModel.new),
          clockProvider.overrideWithValue(() => _now),
          autoUsageStoreProvider.overrideWithValue(auto),
        ],
      );
      container.listen(ledgerProvider, (_, _) {});
      await container.read(ledgerProvider.future);
    });
    tearDown(() async {
      container.dispose();
      await flush();
      await store.close();
      await auto.rows.close();
    });

    test('rows stream into the shared ledger; edits and hides route to the '
        'auto store, never the transactional one', () async {
      auto.rows.add([_entry()]);
      await flush();
      final data = container.read(ledgerProvider).requireValue;
      expect(data.sessions.single.id, _id);
      expect(data.account('auto-codex'), isNotNull);

      final vm = container.read(ledgerProvider.notifier);
      final s = data.sessions.single;
      await vm.saveUsage(
        UsageSession(
          id: s.id,
          accountId: s.accountId,
          title: s.title,
          purpose: Purpose.code,
          occurredAt: s.occurredAt,
          inputTokens: s.inputTokens,
          outputTokens: s.outputTokens,
          modelId: s.modelId,
          dataSource: DataSource.companion,
          note: 'đúng ra là code',
        ),
      );
      // The untouched default title is stored empty so it follows purpose.
      expect(auto.edits[_id], (
        purpose: Purpose.code,
        title: '',
        note: 'đúng ra là code',
      ));
      expect(
        () => vm.saveUsage(
          UsageSession(
            id: s.id,
            accountId: s.accountId,
            title: s.title,
            purpose: s.purpose,
            occurredAt: s.occurredAt,
            inputTokens: 1,
            outputTokens: 1,
            dataSource: DataSource.companion,
          ),
        ),
        throwsArgumentError,
      );
      await vm.deleteUsage(_id);
      expect(auto.hidden, [_id]);
      expect(() => vm.archiveAccount('auto-codex', true), throwsStateError);
      expect(store.documents, isEmpty);

      auto.rows.add([_entry(hidden: true)]);
      await flush();
      expect(container.read(ledgerProvider).requireValue.sessions, isEmpty);
    });
  });
}
