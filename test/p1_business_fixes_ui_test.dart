import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/account_detail_screen.dart';
import 'package:token_ledger/models/cloud_ledger.dart';
import 'package:token_ledger/services/pdf_report_builders.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/utils/formatters.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/widgets/charts.dart';
import 'package:token_ledger/widgets/dashboard_cards.dart';
import 'package:token_ledger/widgets/quota_row.dart';

import 'ledger_viewmodel_test.dart' show MemoryRepository;

void main() {
  final now = DateTime.utc(2026, 11, 3, 10);

  AIAccount account({
    bool archived = false,
    List<QuotaSnapshot> quotas = const [],
  }) => AIAccount(
    id: 'a',
    alias: 'Claude Pro',
    provider: 'Anthropic',
    product: 'Claude',
    billingMode: BillingMode.api,
    plan: '',
    createdAt: now,
    budgetMicros: 20000000,
    archived: archived,
    quotaWindows: quotas,
  );

  QuotaSnapshot quota() => QuotaSnapshot(
    window: '5 giờ',
    usedPercent: 10,
    observedAt: now,
    resetAt: now.add(const Duration(hours: 5)),
  );

  Future<void> pumpBody(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpDetail(WidgetTester tester, AIAccount value) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(
          MemoryRepository()
            ..data = LedgerData(accounts: [value], sessions: []),
        ),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    await container.read(ledgerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const AccountDetailScreen(accountId: 'a'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  UsageSession usage(String id, {int? cost}) => UsageSession(
    id: id,
    accountId: 'a',
    title: 'Work $id',
    purpose: Purpose.code,
    occurredAt: now,
    costMicros: cost,
  );

  test('a day with only unknown costs is null, an empty day is 0', () {
    final daily = UsageCalculator.dailyCosts([usage('u')], now);
    expect(daily.last, isNull);
    expect(daily.first, 0);
    final mixed = [usage('u'), usage('v', cost: 5)];
    expect(UsageCalculator.dailyCosts(mixed, now).last, 5);
  });

  test('PDF rows do not print unknown figures as zero', () {
    final cells = PdfReportBuilders.accountRow(account(), [usage('u')]);
    expect(cells[4], 'Chưa biết');
    expect(cells[5], 'Chưa biết');
  });

  test('PDF rows sum known figures and an idle account stays zero', () {
    final cells = PdfReportBuilders.accountRow(account(), [
      usage('u'),
      usage('v', cost: 1500000),
    ]);
    expect(cells[3], '2');
    expect(cells[4], r'$1.50');
    expect(PdfReportBuilders.accountRow(account(), [])[4], r'$0.00');
  });

  test('errorText strips Dart prefixes and hides internal errors', () {
    expect(errorText(StateError('Lỗi A')), 'Lỗi A');
    expect(errorText(ArgumentError('Lỗi B')), 'Lỗi B');
    expect(errorText(TypeError()), isNot(contains('Type')));
    expect(
      errorText(const CloudLedgerFailure(CloudLedgerProblem.conflict, 'Lỗi C')),
      'Lỗi C',
    );
  });

  testWidgets('balance card names the exceeded account and unknown costs', (
    tester,
  ) async {
    await pumpBody(
      tester,
      DashboardBalanceCard(
        budgetAccounts: [account()],
        remaining: 80000000,
        budget: 120000000,
        spent: 40000000,
        budgetWarning: true,
        warningPercent: 80,
        alerts: [BudgetAlert(account(), 40000000)],
        unknownCostCount: 2,
      ),
    );
    expect(find.text(r'Claude Pro đã vượt: $40.00 / $20.00'), findsOneWidget);
    expect(find.textContaining('2 phiên trong kỳ'), findsOneWidget);
  });

  testWidgets('chart shows a dash for an unknown day, not zero dollars', (
    tester,
  ) async {
    await pumpBody(
      tester,
      UsageBarChart(
        values: const [null, 0, 0, 0, 0, 0, 1000000],
        now: DateTime(2026, 11, 3),
      ),
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.text(r'$1.00'), findsOneWidget);
  });

  testWidgets('archived account offers no quota edits', (tester) async {
    await pumpDetail(tester, account(archived: true, quotas: [quota()]));
    expect(find.text('Thêm cửa sổ'), findsNothing);
    expect(find.textContaining('Khôi phục để cập nhật'), findsOneWidget);
    expect(tester.widget<QuotaRow>(find.byType(QuotaRow)).onTap, isNull);
  });

  testWidgets('active account still offers quota actions', (tester) async {
    await pumpDetail(tester, account());
    expect(find.text('Thêm cửa sổ'), findsOneWidget);
    expect(find.textContaining('Khôi phục để cập nhật'), findsNothing);
  });

  testWidgets('account holding quota explains deletion instead of failing', (
    tester,
  ) async {
    await pumpDetail(tester, account(quotas: [quota()]));
    expect(find.text('Xóa tài khoản rỗng'), findsNothing);
    expect(find.textContaining('Xóa các cửa sổ hạn mức'), findsOneWidget);
  });

  testWidgets('truly empty account can be deleted', (tester) async {
    await pumpDetail(tester, account());
    expect(find.text('Xóa tài khoản rỗng'), findsOneWidget);
    expect(find.textContaining('Xóa các cửa sổ hạn mức'), findsNothing);
  });
}
