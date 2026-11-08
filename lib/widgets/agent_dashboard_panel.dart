import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_dashboard.dart';
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
import 'token_limit_dialog.dart';

class AgentDashboardPanel extends ConsumerStatefulWidget {
  const AgentDashboardPanel({super.key, required this.onAnalytics});
  final VoidCallback onAnalytics;
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.totalTokens == null
                          ? '—'
                          : compactTokens(source.totalTokens),
                      style: text.headlineMedium,
                    ),
                    Text(
                      source.totalTokens == null
                          ? 'chưa có số token'
                          : source.tokenLabel,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (quota != null) ...[
                const SizedBox(width: AppSpace.md),
                QuotaRing(usedPercent: quota.usedPercent, level: level),
              ],
            ],
          ),
          if (quota != null) ...[
            const Divider(height: AppSpace.xl),
            Text(
              'Quota ${quota.displayLabel} · đặt lại ${shortTime(quota.resetsAt)}',
              style: text.bodySmall,
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
