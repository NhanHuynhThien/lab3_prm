import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/data_scope_picker.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/range_picker.dart';
import 'usage_form_screen.dart';

export '../widgets/quota_row.dart';
export '../widgets/range_picker.dart';
export '../widgets/usage_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    required this.onAccounts,
    required this.onAnalytics,
  });

  final VoidCallback onAccounts, onAnalytics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ledgerProvider);
    final feedback = ledgerFeedback(state, 'Tổng quan');
    if (feedback != null) return feedback;
    final data = state.requireValue;
    final projection = ref.watch(dashboardProjectionProvider);

    final balance = DashboardBalanceCard(
      budgetAccounts: projection.budgetAccounts,
      remaining: projection.remaining,
      budget: projection.budget,
      spent: projection.spent,
      budgetWarning: projection.budgetWarning,
      warningPercent: projection.warningPercent,
    );
    final metrics = DashboardMetricsCard(
      summary: projection.summary,
      activeAccountsCount: data.accounts.where((a) => !a.archived).length,
    );
    final trend = DashboardTrendCard(
      sessions: projection.sessions,
      dailyCosts: projection.dailyCosts,
      now: projection.now,
    );
    final quota = DashboardQuotaCard(
      accounts: data.accounts,
      now: projection.now,
      onAccounts: onAccounts,
    );
    final latest = DashboardRecentCard(
      sessions: projection.sessions,
      recentSessions: projection.recentSessions,
      data: data,
    );
    final purpose = DashboardPurposeCard(
      shares: projection.shares,
      summaryCount: projection.summary.count,
      onAnalytics: onAnalytics,
    );

    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        PageHeading(
          'Tổng quan',
          'AI đang hỗ trợ công việc của bạn như thế nào?',
          action: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const UsageFormScreen()),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Ghi sử dụng'),
          ),
        ),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [RangePicker(), DataScopePicker()],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 680
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: balance),
                      const SizedBox(width: 16),
                      Expanded(child: metrics),
                    ],
                  ),
                )
              : Column(
                  children: [balance, const SizedBox(height: 16), metrics],
                ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 800
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: trend),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: quota),
                  ],
                )
              : Column(children: [trend, const SizedBox(height: 16), quota]),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 800
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: latest),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: purpose),
                  ],
                )
              : Column(children: [latest, const SizedBox(height: 16), purpose]),
        ),
      ],
    );
  }
}
