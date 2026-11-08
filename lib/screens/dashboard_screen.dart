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
    if (showProviderFirst) {
      // Agents lead this layout, so manual logging stays one tap away.
      return Stack(
        children: [
          _Page(
            bottomInset: AppSpace.button + AppSpace.xl,
            children: [
              AgentDashboardPanel(onAnalytics: onAnalytics),
              const _LedgerRecap(),
            ],
          ),
          PositionedDirectional(
            end: AppSpace.lg,
            bottom: AppSpace.lg,
            child: FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _openUsageForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ghi sử dụng'),
            ),
          ),
        ],
      );
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
    final latest = DashboardRecentCard(
      sessions: projection.sessions,
      recentSessions: projection.recentSessions,
      data: data,
    );
    return _Page(
      children: [
        const PageHeading(
          'Tổng quan',
          'AI đang hỗ trợ công việc của bạn như thế nào?',
        ),
        FilterBar(
          leading: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => _openUsageForm(context),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Ghi sử dụng', textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 24),
        if (projection.budgetAccounts.isNotEmpty)
          _CardRow(left: balance, right: metrics, breakpoint: 680, leftFlex: 2)
        else
          metrics,
        const SizedBox(height: 16),
        if (projection.dailyCosts.any((cost) => cost != 0))
          _CardRow(
            left: DashboardTrendCard(
              dailyCosts: projection.dailyCosts,
              now: projection.now,
            ),
            right: latest,
          )
        else
          latest,
        const SizedBox(height: 16),
        const OptionalSourcePrompt(),
      ],
    );
  }
}

/// Shown only once the manual ledger has entries in the selected range.
class _LedgerRecap extends ConsumerWidget {
  const _LedgerRecap();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      dashboardProjectionProvider.select((p) => p.summary),
    );
    if (summary.count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg),
      child: DashboardLedgerSummaryCard(
        summary: summary,
        rangeLabel: ref.watch(rangeProvider).label,
      ),
    );
  }
}

void _openUsageForm(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => const UsageFormScreen()),
);

class _Page extends StatelessWidget {
  const _Page({required this.children, this.bottomInset = 0});
  final List<Widget> children;

  /// Extra space below the content, e.g. so a floating button never covers it.
  final double bottomInset;
  @override
  Widget build(BuildContext context) {
    final edge = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 28.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpace.dashboardWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(edge, edge, edge, edge + bottomInset),
          children: children,
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
