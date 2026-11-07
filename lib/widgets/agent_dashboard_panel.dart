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
import 'common.dart';
import 'provider_brand_icon.dart';
import 'token_limit_dialog.dart';

class AgentDashboardPanel extends ConsumerWidget {
  const AgentDashboardPanel({super.key, required this.onAnalytics});
  final VoidCallback onAnalytics;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = AgentDashboard(
      ref.watch(providerSourcesProvider),
      ref.watch(nowProvider),
    );
    final sync = ref.watch(providerSyncProvider);
    void connections() => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ProviderConnectionsScreen(),
      ),
    );
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
              onPressed: sync.working
                  ? null
                  : sync.enabled
                  ? ref.read(providerSyncProvider.notifier).refresh
                  : connections,
              icon: const Icon(Icons.sync_rounded),
            ),
            IconButton(
              tooltip: 'Quản lý các nguồn AI',
              onPressed: connections,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        if (sync.working)
          const LinearProgressIndicator(semanticsLabel: 'Cập nhật agent'),
        if (sync.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.lg),
            child: Text(
              sync.error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        const SizedBox(height: AppSpace.sm),
        if (dashboard.connected.isEmpty)
          EmptyFeedback(
            title: 'Chưa có agent nào',
            message: 'Kết nối Codex, Claude hoặc Gemini để theo dõi token.',
            action: 'Kết nối nguồn AI',
            onAction: connections,
          ),
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
                for (final source in dashboard.connected)
                  SizedBox(
                    width: width,
                    child: _AgentCard(
                      source: source,
                      dashboard: dashboard,
                      onTap: () {
                        ref
                            .read(selectedSourceProvider.notifier)
                            .select(source.id);
                        onAnalytics();
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
    final alertAt = ref.watch(tokenLimitsProvider)[key];
    final fresh = source.status == 'ready' && !source.stale(dashboard.now);
    final text = Theme.of(context).textTheme;
    return Panel(
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  source.totalTokens == null
                      ? '—'
                      : compactTokens(source.totalTokens),
                  style: text.headlineMedium,
                ),
              ),
              Text(
                source.totalTokens == null
                    ? 'chưa có số token'
                    : source.tokenLabel,
                style: text.bodySmall,
              ),
            ],
          ),
          const Divider(height: AppSpace.xl),
          if (quota == null)
            Text(
              'Chưa có hạn mức hiện hành để cảnh báo.',
              style: text.bodySmall,
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quota ${quota.displayLabel} · đặt lại ${shortTime(quota.resetsAt)}',
                    style: text.bodySmall,
                  ),
                ),
                Text(
                  'đã dùng ${quota.usedPercent.toStringAsFixed(0)}%',
                  style: text.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            AnimatedProgress(
              value: quota.usedPercent / 100,
              color: alertAt != null && quota.usedPercent >= alertAt
                  ? AppColors.danger
                  : quota.usedPercent >= 75
                  ? AppColors.amber
                  : AppColors.primary,
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
