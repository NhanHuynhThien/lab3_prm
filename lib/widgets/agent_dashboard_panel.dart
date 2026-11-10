import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_dashboard.dart';
import '../models/auto_usage.dart';
import '../models/provider_usage.dart';
import '../screens/provider_connections_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/provider_sources_viewmodel.dart';
import '../viewmodels/provider_sync_viewmodel.dart';
import '../viewmodels/token_limit_viewmodel.dart';
import 'agent_summary_card.dart';
import 'common.dart';
import 'provider_brand_icon.dart';
import 'quota_ring.dart';
import 'range_picker.dart';
import 'token_limit_dialog.dart';

class AgentDashboardPanel extends ConsumerStatefulWidget {
  const AgentDashboardPanel({
    super.key,
    required this.onAnalytics,
    this.filter,
  });
  final VoidCallback onAnalytics;

  /// Period filter shown right under the title, so it visibly governs every
  /// figure below it, the agent cards included.
  final Widget? filter;
  @override
  ConsumerState<AgentDashboardPanel> createState() =>
      _AgentDashboardPanelState();
}

class _AgentDashboardPanelState extends ConsumerState<AgentDashboardPanel> {
  /// Show only agents that need attention; set from the summary card.
  bool _attentionOnly = false;

  void _connections() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const ProviderConnectionsScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final dashboard = AgentDashboard(
      ref.watch(providerSourcesProvider),
      ref.watch(nowProvider),
    );
    final sync = ref.watch(providerSyncProvider);
    final syncAction = sync.working
        ? null
        : sync.enabled
        ? ref.read(providerSyncProvider.notifier).refresh
        : _connections;
    // A filter with nothing left to match falls back to every agent.
    final filtering = _attentionOnly && dashboard.attention > 0;
    final agents = filtering
        ? dashboard.connected.where(dashboard.needsAttention)
        : dashboard.connected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Tổng quan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    dashboard.lastUpdated == null
                        ? 'Kết nối nguồn để bắt đầu theo dõi.'
                        : 'Cập nhật lúc ${shortTime(dashboard.lastUpdated!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: sync.enabled ? 'Cập nhật các agent' : 'Kết nối agent',
              onPressed: syncAction,
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
        if (sync.working)
          const LinearProgressIndicator(semanticsLabel: 'Cập nhật agent'),
        if (sync.error case final error?) ...[
          const SizedBox(height: AppSpace.sm),
          InlineErrorBanner(message: error, onRetry: syncAction),
          const SizedBox(height: AppSpace.sm),
        ],
        const SizedBox(height: AppSpace.sm),
        if (widget.filter case final filter?) ...[
          filter,
          const SizedBox(height: AppSpace.lg),
        ],
        if (dashboard.connected.isEmpty)
          EmptyFeedback(
            title: 'Chưa có agent nào',
            message: 'Kết nối Codex, Claude hoặc Gemini để theo dõi token.',
            action: 'Kết nối nguồn AI',
            onAction: _connections,
          )
        else ...[
          AgentSummaryCard(
            dashboard: dashboard,
            attentionOnly: filtering,
            onAttentionTap: () => setState(() => _attentionOnly = !filtering),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= AppSpace.dashboardGridBreakpoint
                ? 2
                : 1;
            final width = (c.maxWidth - AppSpace.lg * (columns - 1)) / columns;
            return Wrap(
              spacing: AppSpace.lg,
              runSpacing: AppSpace.lg,
              children: [
                for (final source in agents)
                  SizedBox(
                    width: width,
                    child: _AgentCard(
                      source: source,
                      dashboard: dashboard,
                      onTap: () {
                        ref
                            .read(selectedSourceProvider.notifier)
                            .select(source.id);
                        widget.onAnalytics();
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Every agent card has the same two rows, whatever the source reports:
/// tokens in the selected period (from the ledger) and the current quota.
/// A missing figure says so instead of collapsing the row.
class _AgentCard extends ConsumerWidget {
  const _AgentCard({
    required this.source,
    required this.dashboard,
    required this.onTap,
  });
  final ProviderUsage source;
  final AgentDashboard dashboard;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = dashboard.limiting(source);
    final key = agentLimitKey(source.id);
    final alertAt = ref.watch(tokenLimitsProvider.select((m) => m[key]));
    final level = quota == null
        ? QuotaLevel.normal
        : AgentDashboard.level(quota.usedPercent, alertAt);
    final fresh = source.status == 'ready' && !source.stale(dashboard.now);
    final text = Theme.of(context).textTheme;
    final perTask = autoProviders.containsKey(source.id);
    final account = autoAccountId(source.id);
    final sessions = ref
        .watch(filteredSessionsProvider)
        .where((s) => s.accountId == account)
        .toList();
    final tokens = sessions.fold(0, (n, s) => n + (s.knownTokens ?? 0));
    final period = rangeLabelOf(
      ref.watch(rangeProvider),
      ref.watch(customDaysProvider),
    );
    return Panel(
      color: level.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProviderBrandIcon(source.id),
              const SizedBox(width: AppSpace.md),
              Expanded(child: Text(source.name, style: text.titleLarge)),
              if (!fresh) const StatusTag('Cần cập nhật', neutral: true),
              IconButton(
                tooltip: 'Phân tích ${source.name}',
                onPressed: onTap,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text('Token · $period', style: text.bodySmall),
          const SizedBox(height: 2),
          if (perTask)
            Text(
              '${compactTokens(tokens)} · ${sessions.length} phiên',
              style: text.headlineSmall,
            )
          else
            Text(
              'Nguồn này không cung cấp số token',
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          const Divider(height: AppSpace.xl),
          Text('Hạn mức hiện tại', style: text.bodySmall),
          const SizedBox(height: AppSpace.sm),
          if (quota == null)
            Text(
              source.windows.isEmpty
                  ? 'Nguồn chưa cung cấp hạn mức.'
                  : 'Hạn mức đã cũ, chờ Companion cập nhật.',
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            )
          else ...[
            Row(
              children: [
                QuotaRing(usedPercent: quota.usedPercent, level: level),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quota.usageLabel, style: text.titleMedium),
                      Text(
                        '${quota.scopeLabel} · đặt lại ${resetLabel(quota.resetsAt, dashboard.now)}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    showTokenLimitDialog(context, ref, key, percent: true),
                icon: Icon(
                  alertAt == null
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_outlined,
                  size: 18,
                ),
                label: Text(
                  alertAt == null ? 'Đặt cảnh báo %' : 'Cảnh báo ở $alertAt%',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
