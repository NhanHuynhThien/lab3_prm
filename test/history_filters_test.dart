import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/history_screen.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

void main() {
  final now = DateTime.utc(2026, 11, 20, 5);

  AIAccount account(String id, String provider) => AIAccount(
    id: id,
    alias: 'TK $id',
    provider: provider,
    product: 'Tool $id',
    billingMode: BillingMode.api,
    plan: '',
    createdAt: DateTime.utc(2026),
  );

  UsageSession usage(
    String title,
    String accountId,
    Purpose purpose, [
    DateTime? at,
  ]) => UsageSession(
    id: title,
    accountId: accountId,
    title: title,
    purpose: purpose,
    occurredAt: at ?? now,
  );

  group('Tháng trước', () {
    List<String> ids(List<UsageSession> rows, DateTime at, String zone) =>
        UsageCalculator.filter(
          rows,
          at,
          range: UsageRange.lastMonth,
          timezone: zone,
        ).map((s) => s.id).toList();

    test('covers the whole previous month and excludes this month', () {
      final rows = [
        usage('sep', 'a', Purpose.code, DateTime.utc(2026, 9, 30)),
        usage('oct-1', 'a', Purpose.code, DateTime.utc(2026, 10, 1)),
        usage('oct-31', 'a', Purpose.code, DateTime.utc(2026, 10, 31, 23)),
        usage('nov-1', 'a', Purpose.code, DateTime.utc(2026, 11, 1)),
      ];
      expect(ids(rows, now, 'UTC'), ['oct-31', 'oct-1']);
    });

    test('January reaches back to December of the previous year', () {
      final rows = [
        usage('dec', 'a', Purpose.code, DateTime.utc(2025, 12, 15)),
        usage('jan', 'a', Purpose.code, DateTime.utc(2026, 1, 2)),
      ];
      expect(ids(rows, DateTime.utc(2026, 1, 10), 'UTC'), ['dec']);
    });

    test('month boundaries follow the reporting timezone', () {
      // 18:00 UTC on 31/10 is already 01/11 in Ho Chi Minh City.
      final rows = [
        usage('edge', 'a', Purpose.code, DateTime.utc(2026, 10, 31, 18)),
      ];
      expect(ids(rows, now, 'UTC'), ['edge']);
      expect(ids(rows, now, 'Asia/Ho_Chi_Minh'), isEmpty);
    });
  });

  group('history filters', () {
    Future<void> pump(
      WidgetTester tester, {
      Widget page = const HistoryScreen(),
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(
            MemoryRepository()
              ..data = LedgerData(
                accounts: [account('a', 'OpenAI'), account('b', 'Anthropic')],
                sessions: [
                  usage('Viết API', 'a', Purpose.code),
                  usage('Sửa lỗi login', 'a', Purpose.debug),
                  usage('Review PR', 'b', Purpose.review),
                ],
              ),
          ),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      await container.read(ledgerProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildAppTheme(), home: page),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester, String menu, String item) async {
      await tester.tap(find.text(menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item).last);
      await tester.pumpAndSettle();
    }

    testWidgets('starts unfiltered with no clear action', (tester) async {
      await pump(tester);
      expect(find.textContaining('3 phiên ·'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsNothing);
    });

    testWidgets('filters by account, purpose and provider', (tester) async {
      await pump(tester);
      await choose(tester, 'Mọi tài khoản', 'TK a');
      expect(find.textContaining('2 phiên ·'), findsOneWidget);
      expect(find.text('Review PR'), findsNothing);
      await choose(tester, 'Mọi mục đích', 'Sửa lỗi');
      expect(find.textContaining('1 phiên ·'), findsOneWidget);
      expect(find.text('Viết API'), findsNothing);
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 phiên ·'), findsOneWidget);
      await choose(tester, 'Mọi nhà cung cấp', 'Anthropic');
      expect(find.textContaining('1 phiên ·'), findsOneWidget);
      expect(find.text('Review PR'), findsOneWidget);
    });

    testWidgets('choosing "all" removes a single filter', (tester) async {
      await pump(tester);
      await choose(tester, 'Mọi mục đích', 'Code review');
      expect(find.textContaining('1 phiên ·'), findsOneWidget);
      await choose(tester, 'Code review', 'Mọi mục đích');
      expect(find.textContaining('3 phiên ·'), findsOneWidget);
    });

    testWidgets('provider change drops an account it could never match', (
      tester,
    ) async {
      await pump(tester);
      await choose(tester, 'Mọi tài khoản', 'TK a');
      await choose(tester, 'Mọi nhà cung cấp', 'Anthropic');
      expect(find.text('Mọi tài khoản'), findsOneWidget);
      expect(find.text('Review PR'), findsOneWidget);
    });

    testWidgets('drill-down opens filtered and can be widened', (tester) async {
      await pump(tester, page: const HistoryScreen(purpose: Purpose.review));
      expect(find.textContaining('1 phiên ·'), findsOneWidget);
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 phiên ·'), findsOneWidget);
    });

    testWidgets('clearing the account leaves the budget cycle view', (
      tester,
    ) async {
      await pump(
        tester,
        page: const HistoryScreen(accountId: 'a', useAccountCycle: true),
      );
      expect(find.textContaining('Kỳ ngân sách tài khoản'), findsOneWidget);
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kỳ ngân sách tài khoản'), findsNothing);
      expect(find.text('Tháng này'), findsOneWidget);
    });
  });
}
