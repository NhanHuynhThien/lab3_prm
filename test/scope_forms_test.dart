import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';
import 'package:token_ledger/services/demo_seed.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'support/scope_forms_harness.dart';

void main() {
  late ScopeFormsHarness h;

  setUp(() async {
    h = ScopeFormsHarness();
    await h.init();
  });

  tearDown(() => h.container.dispose());

  for (final width in [360.0, 412.0]) {
    testWidgets(
      'model/defaults/cycle save failure retains new fields and retry at ${width.toInt()}',
      (tester) async {
        await h.open(
          tester,
          AccountFormScreen(account: h.repo.data!.account('a')),
          width,
        );
        final model = find.byKey(const ValueKey('account-model'));
        await h.reveal(tester, model);
        await tester.enterText(model, 'model-riêng');
        await h.reveal(tester, find.text('Kiểm thử'));
        await tester.tap(find.text('Kiểm thử'));
        await tester.pumpAndSettle();
        final zone = find.byKey(const ValueKey('account-timezone'));
        await h.reveal(tester, zone);
        await tester.enterText(zone, 'America/New_York');
        final cycle = find.byKey(const ValueKey('account-cycle'));
        await h.reveal(tester, cycle);
        await tester.enterText(cycle, '31');
        h.repo.failWrites = true;
        await tester.tap(find.text('Lưu tài khoản'));
        await tester.pumpAndSettle();
        expect(h.repo.data!.account('a')!.defaultModelId, 'model-gợi-ý');
        expect(find.byType(AccountFormScreen), findsOneWidget);
        await h.reveal(tester, model, step: -240);
        expect(
          tester.widget<TextFormField>(model).controller!.text,
          'model-riêng',
        );
        h.repo.failWrites = false;
        await tester.tap(find.text('Lưu tài khoản'));
        await tester.pumpAndSettle();
        final saved = h.repo.data!.account('a')!;
        expect(saved.defaultModelId, 'model-riêng');
        expect(saved.defaultPurposes, [Purpose.review, Purpose.test]);
        expect(saved.timezone, 'America/New_York');
        expect(saved.cycleStartDay, 31);
        expect(saved.quotaWindows.single.window, 'Hàng tuần');
        expect(find.text('Home fixture'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'usage model/purpose suggestions editable, retry preserves provenance at ${width.toInt()}',
      (tester) async {
        await h.open(tester, const UsageFormScreen(accountId: 'a'), width);
        expect(find.text('Mục đích: Code review'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).first,
          'Công việc thực',
        );
        final model = find.byKey(const ValueKey('usage-model'));
        await h.reveal(tester, model);
        expect(
          tester.widget<TextFormField>(model).controller!.text,
          'model-gợi-ý',
        );
        await tester.enterText(model, 'model-cho-phiên');
        h.repo.failWrites = true;
        await tester.tap(find.text('Lưu phiên sử dụng'));
        await tester.pumpAndSettle();
        expect(h.repo.data!.sessions, isEmpty);
        expect(
          tester.widget<TextFormField>(model).controller!.text,
          'model-cho-phiên',
        );
        h.repo.failWrites = false;
        await tester.tap(find.text('Lưu phiên sử dụng'));
        await tester.pumpAndSettle();
        final saved = h.repo.data!.sessions.single;
        expect(saved.modelId, 'model-cho-phiên');
        expect(saved.purpose, Purpose.review);
        expect(saved.dataSource, DataSource.manual);
        expect(saved.isDemo, isFalse);
        expect(saved.costMicros, isNull);
        expect(saved.effectiveCostBasis, CostBasis.unknown);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'chip-only changes guard Back and optional model/default purposes can be cleared',
    (tester) async {
      await h.open(
        tester,
        AccountFormScreen(account: h.repo.data!.account('a')),
        360,
      );
      final chip = find.widgetWithText(FilterChip, 'Code review');
      await h.reveal(tester, chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      final model = find.byKey(const ValueKey('account-model'));
      await h.reveal(tester, model, step: -240);
      await tester.enterText(model, '');
      await tester.tap(find.text('Lưu tài khoản'));
      await tester.pumpAndSettle();
      expect(h.repo.data!.account('a')!.defaultModelId, isNull);
      expect(h.repo.data!.account('a')!.defaultPurposes, isEmpty);
      expect(h.repo.data!.account('a')!.quotaWindows.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new account retries keep creation timestamp even when clock advances',
    (tester) async {
      var clock = h.now;
      h.container.dispose();
      h.container = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(h.repo),
          clockProvider.overrideWithValue(() => clock),
        ],
      );
      await h.container.read(ledgerProvider.future);
      await h.open(tester, const AccountFormScreen(), 360);
      await tester.enterText(find.byType(TextFormField).first, 'Retry clock');
      h.repo.failWrites = true;
      await tester.tap(find.text('Lưu tài khoản'));
      await tester.pumpAndSettle();
      clock = clock.add(const Duration(minutes: 2));
      h.repo.failWrites = false;
      await tester.tap(find.text('Lưu tài khoản'));
      await tester.pumpAndSettle();
      final saved = h.repo.data!.accounts.singleWhere(
        (a) => a.alias == 'Retry clock',
      );
      expect(saved.createdAt.isAtSameMomentAs(h.now), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new usage suggests the selected source instead of accidentally recording into a seed account',
    (tester) async {
      final seed = createDemoSeed(h.now);
      h.repo.data = h.repo.data!.copyWith(
        accounts: [...seed.accounts, ...h.repo.data!.accounts],
        sessions: seed.sessions,
      );
      h.container.invalidate(ledgerProvider);
      await h.container.read(ledgerProvider.future);
      await h.open(tester, const UsageFormScreen(), 360);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        'a',
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'Công việc nhập tay sau seed',
      );
      await tester.tap(find.text('Lưu phiên sử dụng'));
      await tester.pumpAndSettle();
      final saved = h.repo.data!.sessions.last;
      expect(saved.accountId, 'a');
      expect(saved.dataSource, DataSource.manual);
      expect(saved.isDemo, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
