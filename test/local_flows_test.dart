import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:token_ledger/screens/accounts_screen.dart';
import 'package:token_ledger/screens/shell_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';

import 'support/demo_seed.dart';

import 'package:token_ledger/services/ledger_repository.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_stability_test.dart' show PendingRepository;
import 'ledger_viewmodel_test.dart' show MemoryRepository;

void main() {
  final now = DateTime(2026, 10, 21, 10);
  const storage = LocalLedgerRepository.storageKey;
  const backup = LocalLedgerRepository.backupKey;

  ProviderContainer owner(LedgerRepository repository) => ProviderContainer(
    overrides: [
      ledgerRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => now),
    ],
  );

  Future<void> open(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen, {
    double width = 412,
    GlobalKey<NavigatorState>? navigator,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigator,
          theme: buildAppTheme(),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 412.0]) {
    testWidgets(
      'B04 archived list/detail/history/edit/delete/restore at ${width.toInt()}dp',
      (tester) async {
        final repository = MemoryRepository();
        final container = owner(repository);
        addTearDown(container.dispose);
        await container.read(ledgerProvider.future);
        final vm = container.read(ledgerProvider.notifier);
        await vm.archiveAccount('codex', true);
        await open(
          tester,
          container,
          const Scaffold(body: AccountsScreen()),
          width: width,
        );
        await tester.tap(find.text('Đã lưu trữ'));
        await tester.pumpAndSettle();
        expect(find.text('Codex học tập'), findsOneWidget);
        await tester.tap(find.byTooltip('Mở chi tiết tài khoản'));
        await tester.pumpAndSettle();
        expect(find.text('Ghi sử dụng cho tài khoản'), findsNothing);
        expect(find.text('Xóa tài khoản rỗng'), findsNothing);
        await reveal(tester, find.text('Lịch sử tài khoản'));
        await tester.tap(find.text('Lịch sử tài khoản'));
        await tester.pumpAndSettle();
        expect(find.textContaining('4 phiên · \$5.86'), findsOneWidget);
        await reveal(tester, find.text('Sửa lỗi Google Sign-In'));
        await tester.tap(find.text('Sửa lỗi Google Sign-In'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Sửa phiên'));
        await tester.tap(find.text('Sửa phiên'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Bạn vẫn có thể sửa phiên lịch sử'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          'B04 sửa phiên',
        );
        await tester.tap(find.text('Lưu phiên sử dụng'));
        await tester.pumpAndSettle();
        expect(
          repository.data!.sessions.firstWhere((s) => s.id == 'seed-1').title,
          'B04 sửa phiên',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await reveal(tester, find.text('B04 sửa phiên'));
        await tester.tap(find.text('B04 sửa phiên'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Xóa phiên'));
        await tester.tap(find.text('Xóa phiên'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
        expect(repository.data!.sessions.length, 12);
        await tester.tap(find.text('Xóa phiên'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Xóa phiên'));
        await tester.pumpAndSettle();
        expect(find.textContaining('3 phiên · \$4.90'), findsOneWidget);
        final total = UsageCalculator.summarize(repository.data!.sessions);
        expect(total.costMicros, 11880000);
        expect(total.tokens, 248000);
        expect(repository.data!.account('codex')!.archived, isTrue);
        await expectLater(vm.deleteAccount('codex'), throwsStateError);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Khôi phục tài khoản'));
        await tester.tap(find.text('Khôi phục tài khoản'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Khôi phục tài khoản'),
        );
        await tester.pumpAndSettle();
        expect(repository.data!.account('codex')!.archived, isFalse);
        expect(find.text('Ghi sử dụng cho tài khoản'), findsOneWidget);
        expect(tester.takeException(), isNull);
        container.dispose();
      },
    );

    testWidgets('corrupt local data stays protected through retry at $width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({storage: '{original broken'});
      final prefs = await SharedPreferences.getInstance();
      final container = owner(LocalLedgerRepository(prefs));
      addTearDown(container.dispose);
      await open(tester, container, const ShellScreen(), width: width);
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(prefs.getString(storage), '{original broken');
      expect(find.text('Khôi phục dữ liệu local'), findsNothing);
      expect(prefs.get(backup), isNull);
      expect(container.read(ledgerProvider).hasError, isTrue);
    });
  }

  testWidgets(
    'B06 double tap then forced route removal does not pop another route or duplicate save',
    (tester) async {
      final repository = PendingRepository()..data = createDemoSeed(now);
      final container = owner(repository);
      addTearDown(container.dispose);
      await container.read(ledgerProvider.future);
      final navigator = GlobalKey<NavigatorState>();
      await open(
        tester,
        container,
        const Scaffold(body: Text('Home fixture')),
        navigator: navigator,
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const UsageFormScreen(accountId: 'codex'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Route removed during save',
      );
      repository.pending = Completer<void>();
      await tester.tap(find.text('Lưu phiên sử dụng'));
      await tester.tap(find.text('Lưu phiên sử dụng'));
      await tester.pump();
      expect(repository.writes, 1);
      navigator.currentState!.pop(); // Simulate an ancestor removing the form.
      await tester.pumpAndSettle();
      expect(find.text('Home fixture'), findsOneWidget);
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(repository.data!.sessions.length, 13);
      expect(find.text('Home fixture'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
