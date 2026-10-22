import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/account_detail_screen.dart';
import 'package:token_ledger/screens/account_form_screen.dart';
import 'package:token_ledger/screens/login_screen.dart';
import 'package:token_ledger/screens/quota_form_screen.dart';
import 'package:token_ledger/screens/shell_screen.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';

import 'support/demo_seed.dart';

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
    testWidgets('B12 empty, not-found and disabled states $width', (
      tester,
    ) async {
      final seed = createDemoSeed(h.now);
      final repo = StateRepository()
        ..data = LedgerData(accounts: [], sessions: []);
      final container = h.owner(repo);
      await container.read(ledgerProvider.future);
      try {
        for (final screen in [
          const AccountDetailScreen(accountId: 'missing'),
          AccountFormScreen(account: seed.accounts.first),
          QuotaFormScreen(account: seed.accounts.first),
          UsageFormScreen(session: seed.sessions.first),
        ]) {
          await h.open(tester, container, screen, width: width, scale: 2);
          await tester.pumpAndSettle();
          expect(find.text('Không tìm thấy tài khoản'), findsOneWidget);
          expect(find.byType(SaveButton), findsNothing);
          expect(tester.takeException(), isNull);
        }
        await h.open(tester, container, const UsageFormScreen(), width: width);
        await tester.pumpAndSettle();
        expect(find.text('Thêm tài khoản trước'), findsOneWidget);
        await tester.tap(find.text('Thêm tài khoản'));
        await tester.pumpAndSettle();
        expect(find.text('Thêm tài khoản AI'), findsOneWidget);
        await h.open(tester, container, const ShellScreen(), width: width);
        await tester.pumpAndSettle();
        for (final tab in ['Tài khoản', 'Phân tích', 'Cá nhân', 'Tổng quan']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await h.open(tester, container, const LoginScreen(), width: width);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Đăng nhập bằng Google'),
              )
              .onPressed,
          isNull,
        );
      } finally {
        await h.close(tester, container);
      }
    });
  }

  testWidgets(
    'B12 removed usage is not resurrected by opening its old edit route',
    (tester) async {
      final seed = createDemoSeed(h.now);
      final repo = StateRepository()
        ..data = LedgerData(accounts: seed.accounts, sessions: []);
      final container = h.owner(repo);
      await container.read(ledgerProvider.future);
      try {
        await h.open(
          tester,
          container,
          UsageFormScreen(session: seed.sessions.first),
        );
        await tester.pumpAndSettle();
        expect(find.text('Không tìm thấy phiên sử dụng'), findsOneWidget);
        expect(find.byType(SaveButton), findsNothing);
        expect(repo.writes, 0);
      } finally {
        await h.close(tester, container);
      }
    },
  );
}
