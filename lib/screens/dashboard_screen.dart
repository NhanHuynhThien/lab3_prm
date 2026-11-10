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
import '../widgets/optional_source_prompt.dart';

export '../widgets/quota_row.dart';
export '../widgets/range_picker.dart';
export '../widgets/usage_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onAnalytics});

  final VoidCallback onAnalytics;

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
    final metrics = DashboardMetricsCard(
      summary: projection.summary,
      hasCost: projection.hasCost,
      rangeLabel: rangeLabelOf(
        ref.watch(rangeProvider),
        ref.watch(customDaysProvider),
      ),
    );
    final latest = DashboardRecentCard(
      sessions: projection.sessions,
      recentSessions: projection.recentSessions,
      data: data,
    );
    // One ledger: Companion rows and manual entries feed the same cards; the
    // agent panel only adds live quota on top when a source is connected.
    return _Page(
      children: [
        // The period filter sits right under the title and governs every
        // figure below it: totals, each agent's tokens, recent sessions.
        if (showProviderFirst) ...[
          AgentDashboardPanel(
            onAnalytics: onAnalytics,
            filter: Column(
              children: [
                const FilterBar(),
                const SizedBox(height: AppSpace.lg),
                metrics,
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          const PageHeading(
            'Tổng quan',
            'AI đang hỗ trợ công việc của bạn như thế nào?',
          ),
          const FilterBar(),
          const SizedBox(height: 24),
        ],
        if (projection.budgetAccounts.isNotEmpty) ...[
          showProviderFirst
              ? balance
              : _CardRow(
                  left: balance,
                  right: metrics,
                  breakpoint: 680,
                  leftFlex: 2,
                ),
          const SizedBox(height: 16),
        ] else if (!showProviderFirst) ...[
          metrics,
          const SizedBox(height: 16),
        ],
        // Cost trend only when costs exist; subscriptions get tokens per day.
        if (projection.hasCost
            ? projection.dailyCosts.any((v) => v != 0)
            : projection.dailyTokens.any((v) => v != 0))
          _CardRow(
            left: DashboardTrendCard(
              dailyCosts: projection.hasCost
                  ? projection.dailyCosts
                  : projection.dailyTokens,
              tokens: !projection.hasCost,
              now: projection.now,
            ),
            right: latest,
          )
        else
          latest,
        if (!showProviderFirst) ...[
          const SizedBox(height: 16),
          const OptionalSourcePrompt(),
        ],
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final edge = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 28.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpace.dashboardWidth),
        child: ListView(padding: EdgeInsets.all(edge), children: children),
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
