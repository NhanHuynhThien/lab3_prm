import 'package:flutter/material.dart';

import '../models/ledger.dart';
import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';

class DashboardMetric extends StatelessWidget {
  const DashboardMetric(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 6),
      Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class DashboardBalanceCard extends StatelessWidget {
  const DashboardBalanceCard({
    super.key,
    required this.budgetAccounts,
    required this.remaining,
    required this.budget,
    required this.spent,
    required this.budgetWarning,
    required this.warningPercent,
    this.alerts = const [],
    this.unknownCostCount = 0,
  });

  final List<BudgetAlert> alerts;
  final int unknownCostCount;
  final List<AIAccount> budgetAccounts;
  final int remaining;
  final int budget;
  final int spent;
  final bool budgetWarning;
  final int warningPercent;

  @override
  Widget build(BuildContext context) => Panel(
    color: AppColors.soft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngân sách còn lại · Kỳ hiện tại',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (budgetAccounts.isEmpty)
          Text(
            'Chưa đặt ngân sách',
            style: Theme.of(context).textTheme.titleLarge,
          )
        else
          AnimatedMoney(micros: remaining),
        const SizedBox(height: 16),
        AnimatedProgress(
          value: budget == 0 ? 0 : spent / budget,
          semanticValue: budgetAccounts.isEmpty ? 'Chưa đặt ngân sách' : null,
          color: remaining < 0 || alerts.any((a) => a.exceeded)
              ? AppColors.danger
              : AppColors.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Đã ghi ${money(spent)} / ${money(budget)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        if (budgetWarning) ...[
          Text(
            'Đã chạm ngưỡng cảnh báo $warningPercent% ngân sách kỳ này.',
            key: const ValueKey('budget-config-warning'),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.danger),
          ),
          for (final alert in alerts.take(3))
            Text(
              '${alert.account.alias} ${alert.exceeded ? 'đã vượt' : 'đã dùng'}: ${money(alert.spent)} / ${money(alert.budget)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.danger),
            ),
          if (alerts.length > 3)
            Text(
              '+${alerts.length - 3} tài khoản khác',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.danger),
            ),
          const SizedBox(height: AppSpace.sm),
        ],
        if (unknownCostCount > 0) ...[
          Text(
            '$unknownCostCount phiên trong kỳ chưa biết chi phí; số còn lại thực tế có thể thấp hơn.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Text(
          'Ngân sách từng kỳ tài khoản theo nguồn đã chọn; không phải số dư nhà cung cấp.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class DashboardMetricsCard extends StatelessWidget {
  const DashboardMetricsCard({super.key, required this.summary});

  final UsageSummary summary;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardMetric(
                'Chi phí đã ghi',
                money(summary.costMicros),
              ),
            ),
            Expanded(
              child: DashboardMetric(
                'Token đã ghi',
                compactTokens(summary.tokens),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${summary.count} phiên sử dụng',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (summary.unknownCost > 0 || summary.unknownTokens > 0) ...[
          const SizedBox(height: 4),
          Text(
            [
              if (summary.unknownCost > 0)
                '${summary.unknownCost} phiên chưa biết chi phí',
              if (summary.unknownTokens > 0)
                '${summary.unknownTokens} phiên chưa biết token',
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}
