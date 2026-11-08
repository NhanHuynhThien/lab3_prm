import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/screens/shell_screen.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/widgets/dashboard_cards.dart';
import 'package:token_ledger/screens/usage_form_screen.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

void main() {
  for (final width in [360.0, 412.0, 768.0, 1440.0]) {
    testWidgets('demo navigation and dashboard fit ${width.toInt()}dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ledgerRepositoryProvider.overrideWithValue(MemoryRepository()),
            clockProvider.overrideWithValue(() => DateTime(2026, 10, 19, 10)),
          ],
          child: MaterialApp(theme: buildAppTheme(), home: const ShellScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ngân sách còn lại · Kỳ hiện tại'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();
      expect(find.text('Thêm tài khoản'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Phân tích').last);
      await tester.pumpAndSettle();
      expect(find.text('Phân tích sử dụng'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cá nhân').last);
      await tester.pumpAndSettle();
      expect(find.text('Dữ liệu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('empty overview shows only summary and recent usage', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(
            MemoryRepository()..data = LedgerData(accounts: [], sessions: []),
          ),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const ShellScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DashboardMetricsCard), findsOneWidget);
    expect(find.byType(DashboardBalanceCard), findsNothing);
    expect(find.byType(DashboardTrendCard), findsNothing);
    expect(find.byType(DashboardRecentCard), findsOneWidget);
    expect(find.text('Tài khoản active'), findsNothing);
    expect(find.textContaining('0 phiên chưa biết'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usage form rejects empty title and saves a complete session', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(MemoryRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(ledgerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: UsageFormScreen(accountId: 'codex')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu phiên sử dụng'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên công việc.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Test form save');
    // A title/purpose-only log is allowed; missing metrics remain null.
    await tester.tap(find.text('Lưu phiên sử dụng'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(ledgerProvider)
          .requireValue
          .sessions
          .any((s) => s.title == 'Test form save' && s.costMicros == null),
      isTrue,
    );
  });
}
