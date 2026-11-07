import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/range_picker.dart';
import '../widgets/agent_dashboard_panel.dart';
import '../viewmodels/provider_sources_viewmodel.dart';
import '../models/cloud_sync_status.dart';
import '../theme/app_theme.dart';
import '../widgets/provider_ledger_feedback.dart';
import 'usage_form_screen.dart';
import '../widgets/optional_source_prompt.dart';

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
    final cloud = ref.watch(cloudOwnerProvider) != null;
    final showProviderFirst = ref.watch(hasObservedSourcesProvider);
    if (feedback != null) {
      return cloud && showProviderFirst
          ? ProviderLedgerFeedback(
              feedback: feedback,
              header: AgentDashboardPanel(onAnalytics: onAnalytics),
            )
          : feedback;
    }
    final data = state.requireValue;
    final projection = ref.watch(dashboardProjectionProvider);

    final balance = DashboardBalanceCard(
      budgetAccounts: projection.budgetAccounts,
      remaining: projection.remaining,
      budget: projection.budget,
      spent: projection.spent,
      budgetWarning: projection.budgetWarning,
      warningPercent: projection.warningPercent,
      alerts: projection.budgetAlerts,
      unknownCostCount: projection.budgetUnknownCost,
    );
    final metrics = DashboardMetricsCard(summary: projection.summary);
    final trend = DashboardTrendCard(
      dailyCosts: projection.dailyCosts,
      now: projection.now,
    );
    final latest = DashboardRecentCard(
      sessions: projection.sessions,
      recentSessions: projection.recentSessions,
      data: data,
    );
    final recordUsage = FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const UsageFormScreen()),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Ghi sử dụng', textAlign: TextAlign.center),
    );
    final manual = [
      FilterBar(leading: showProviderFirst ? null : recordUsage),
      const SizedBox(height: 24),
      if (projection.budgetAccounts.isNotEmpty)
        _CardRow(left: balance, right: metrics, breakpoint: 680, leftFlex: 2)
      else
        metrics,
      const SizedBox(height: 16),
      if (projection.dailyCosts.any((cost) => cost != 0))
        _CardRow(left: trend, right: latest)
      else
        latest,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpace.dashboardWidth),
        child: ListView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
          ),
          children: [
            PageHeading(
              'Tổng quan',
              showProviderFirst
                  ? 'Tình hình các agent bạn đang sử dụng, trong một dashboard.'
                  : 'AI đang hỗ trợ công việc của bạn như thế nào?',
              action: showProviderFirst ? recordUsage : null,
            ),
            if (showProviderFirst) ...[
              AgentDashboardPanel(onAnalytics: onAnalytics),
              const SizedBox(height: 24),
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  // Reopens when a budget warning appears, so it is never hidden.
                  key: ValueKey('manual-${projection.budgetWarning}'),
                  initiallyExpanded: projection.budgetWarning,
                  title: const Text('Sổ sử dụng thủ công'),
                  subtitle: const Text('Ngân sách và các phiên bạn tự ghi'),
                  tilePadding: EdgeInsets.zero,
                  children: manual,
                ),
              ),
            ] else ...[
              ...manual,
              const SizedBox(height: 16),
              const OptionalSourcePrompt(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Two cards side by side on wide screens, stacked on phones.
class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.left,
    required this.right,
    this.breakpoint = 800,
    this.leftFlex = 3,
  });
  final Widget left, right;
  final double breakpoint;
  final int leftFlex;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth >= breakpoint
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: right),
            ],
          )
        : Column(children: [left, const SizedBox(height: 16), right]),
  );
}
