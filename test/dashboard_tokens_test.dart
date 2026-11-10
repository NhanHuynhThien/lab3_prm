import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/widgets/dashboard_cards.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);
  UsageSession s(DateTime at, {int? input, int? output, int? cost}) =>
      UsageSession(
        id: '${at.millisecondsSinceEpoch}$input',
        accountId: 'auto-codex',
        title: 't',
        purpose: Purpose.code,
        occurredAt: at,
        inputTokens: input,
        outputTokens: output,
        costMicros: cost,
        costBasis: cost == null ? null : CostBasis.manual,
      );

  test('daily tokens: 7 days, null when a day has only unknown tokens', () {
    final days = UsageCalculator.dailyTokens([
      s(DateTime(2026, 11, 10, 9), input: 100, output: 50),
      s(DateTime(2026, 11, 9, 9)),
      s(DateTime(2026, 11, 1, 9), input: 5, output: 5),
    ], now);
    expect(days, [0, 0, 0, 0, 0, null, 150]);
  });

  testWidgets('subscription totals show tokens and sessions, never \$0', (
    tester,
  ) async {
    final summary = UsageCalculator.summarize([
      s(DateTime(2026, 11, 10, 9), input: 100, output: 50),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: DashboardMetricsCard(
            summary: summary,
            hasCost: false,
            rangeLabel: 'Tháng này',
          ),
        ),
      ),
    );
    expect(find.text('Chi phí đã ghi'), findsNothing);
    expect(find.textContaining('chưa biết chi phí'), findsNothing);
    expect(find.text('Phiên'), findsOneWidget);
    expect(find.text('Kỳ: Tháng này'), findsOneWidget);
  });
}
