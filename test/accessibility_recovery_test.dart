import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/screens/accounts_screen.dart';
import 'package:token_ledger/screens/history_screen.dart';
import 'package:token_ledger/screens/profile_screen.dart';
import 'package:token_ledger/screens/quota_form_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/widgets/common.dart';

import 'support/accessibility_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AccessibilityHarness h;

  setUpAll(() async {
    await AccessibilityHarness.loadFonts();
  });

  setUp(() {
    h = AccessibilityHarness();
  });

  for (final width in [360.0, 412.0]) {
    testWidgets('Profile has no sandbox or sample data controls $width', (
      tester,
    ) async {
      final repo = StateRepository();
      final container = h.owner(repo);
      await container.read(ledgerProvider.future);
      final before = repo.data;
      try {
        await h.open(
          tester,
          container,
          const Scaffold(body: ProfileScreen()),
          width: width,
        );
        await tester.pumpAndSettle();
        expect(find.text('Xóa dữ liệu demo'), findsNothing);
        expect(find.text('Khôi phục dữ liệu mẫu'), findsNothing);
        expect(find.text('Mở demo local riêng biệt'), findsNothing);
        expect(repo.data, same(before));
        expect(tester.takeException(), isNull);
      } finally {
        await h.close(tester, container);
      }
    });
  }

  testWidgets(
    'B12 cold usage route loads then errors/retries without an init crash',
    (tester) async {
      final repo = StateRepository()..loading = Completer<LedgerData?>();
      final container = h.owner(repo);
      try {
        await h.open(tester, container, const UsageFormScreen());
        expect(find.byType(LoadingFeedback), findsOneWidget);
        repo.loading!.completeError(StateError('Read failed'));
        repo.loading = null;
        await tester.pumpAndSettle();
        expect(find.text('Thử lại'), findsOneWidget);
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(find.text('Lưu phiên sử dụng'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await h.close(tester, container);
      }
    },
  );

  for (final kind in ['usage', 'account', 'quota', 'history', 'accounts']) {
    testWidgets('B12 $kind reload error/Retry preserves draft or filter', (
      tester,
    ) async {
      final repo = StateRepository();
      final container = h.owner(repo);
      final data = await container.read(ledgerProvider.future);
      final screen = switch (kind) {
        'usage' => const UsageFormScreen(accountId: 'codex'),
        'account' => const AccountFormScreen(),
        'quota' => QuotaFormScreen(account: data.account('codex')!),
        'history' => const HistoryScreen(),
        _ => const Scaffold(body: AccountsScreen()),
      };
      try {
        await h.open(tester, container, screen);
        await tester.pumpAndSettle();
        final field = find.byType(TextField).first;
        await tester.enterText(field, 'Dữ liệu giữ nguyên');
        await tester.pump();
        repo.failReads = true;
        container.invalidate(ledgerProvider);
        await tester.pumpAndSettle();
        expect(find.text('Thử lại'), findsOneWidget);
        repo.failReads = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .controller
              .text,
          'Dữ liệu giữ nguyên',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await h.close(tester, container);
      }
    });
  }

  testWidgets(
    'B12 confirmation guards double tap, failure/retry and removed owner',
    (tester) async {
      var writes = 0;
      var fail = true;
      final gate = Completer<void>();
      Widget button() => ConfirmedActionButton(
        label: 'Xóa phiên',
        icon: Icons.delete_outline,
        title: 'Xóa phiên?',
        message: 'Không thể hoàn tác.',
        onConfirm: () async {
          writes++;
          if (fail) throw StateError('write failed');
          await gate.future;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: button()),
        ),
      );
      final point = tester.getCenter(find.text('Xóa phiên'));
      await tester.tapAt(point);
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa phiên'));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.textContaining('write failed'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Xóa phiên'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa phiên'));
      await tester.pump();
      expect(writes, 2);
      expect(
        tester.widget<TextButton>(find.byType(TextButton).first).onPressed,
        isNull,
      );
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Xóa phiên'), findsOneWidget);
      await tester.tap(find.text('Xóa phiên'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(writes, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'B12 dirty Back remains protected while a form shows a reload error',
    (tester) async {
      final repo = StateRepository();
      final container = h.owner(repo);
      await container.read(ledgerProvider.future);
      try {
        await h.open(
          tester,
          container,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const UsageFormScreen(accountId: 'codex'),
                  ),
                ),
                child: const Text('Mở form'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mở form'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Draft còn nguyên',
        );
        repo.failReads = true;
        container.invalidate(ledgerProvider);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
        await tester.tap(find.text('Tiếp tục sửa'));
        await tester.pumpAndSettle();
        repo.failReads = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .controller
              .text,
          'Draft còn nguyên',
        );
      } finally {
        await h.close(tester, container);
      }
    },
  );
}
