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
import 'common.dart';
import 'provider_brand_icon.dart';

class AgentDashboardPanel extends ConsumerWidget {
  const AgentDashboardPanel({super.key, required this.onAnalytics});
  final VoidCallback onAnalytics;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final dashboard = AgentDashboard(ref.watch(providerSourcesProvider), now);
    final sync = ref.watch(providerSyncProvider);
    final text = Theme.of(context).textTheme;
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
            const Expanded(child: SectionTitle('Dashboard agent')),
            IconButton(
              tooltip: sync.enabled ? 'Cập nhật các agent' : 'Kết nối agent',
              onPressed: sync.working
                  ? null
                  : sync.enabled
                  ? ref.read(providerSyncProvider.notifier).refresh
                  : connections,
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
        Text(
          dashboard.lastUpdated == null
              ? 'Kết nối nguồn để bắt đầu theo dõi.'
              : 'Cập nhật ${shortTime(dashboard.lastUpdated!)} · mỗi nguồn có phạm vi số liệu riêng',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpace.xl),
        Panel(
          color: AppColors.soft,
          child: LayoutBuilder(
            builder: (context, c) {
              final columns = c.maxWidth >= 600 ? 4 : 2;
              final width =
                  (c.maxWidth - AppSpace.lg * (columns - 1)) / columns;
              final items = [
                (
                  '${dashboard.connected.length}',
                  'Agent có dữ liệu',
                  Icons.hub_outlined,
                ),
                ('${dashboard.freshCount}', 'Cập nhật tốt', Icons.sync_rounded),
                (
                  '${dashboard.attention}',
                  'Cần chú ý',
                  Icons.info_outline_rounded,
                ),
                (
                  '${dashboard.quotaCount}',
                  'Cửa sổ quota',
                  Icons.donut_large_rounded,
                ),
              ];
              return Wrap(
                spacing: AppSpace.lg,
                runSpacing: AppSpace.xl,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: _Summary(item.$1, item.$2, item.$3),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        if (sync.working)
          const LinearProgressIndicator(semanticsLabel: 'Cập nhật agent'),
        if (sync.error != null) ...[
          Text(sync.error!, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: AppSpace.lg),
        ],
        if (dashboard.connected.isEmpty)
          EmptyFeedback(
            title: 'Chưa có thống kê agent',
            message: 'Kết nối nguồn bạn sử dụng để xem trạng thái, hạn mức và model có ghi nhận.',
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
                    child: _AgentRow(
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
        TextButton.icon(
          onPressed: connections,
          icon: const Icon(Icons.add_link),
          label: const Text('Quản lý các nguồn AI'),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Token lifetime, lịch sử CLI và quota được giữ đúng nhãn nguồn; dashboard không cộng chúng thành một tổng.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.value, this.label, this.icon);
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(value, style: Theme.of(context).textTheme.displaySmall),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.sm),
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _AgentRow extends StatelessWidget {
  const _AgentRow({
    required this.source,
    required this.dashboard,
    required this.onTap,
  });
  final ProviderUsage source;
  final AgentDashboard dashboard;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final quota = dashboard.limiting(source);
    final remaining = quota == null
        ? null
        : source.remaining(quota, dashboard.now);
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
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          StatusTag(fresh ? 'Đã có số liệu' : 'Cần cập nhật', neutral: !fresh),
          const SizedBox(height: AppSpace.lg),
          if (remaining != null) ...[
            Text(
              'Cửa sổ cần theo dõi · ${quota!.displayLabel}',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              '${remaining.toStringAsFixed(1)}% còn lại',
              style: text.headlineSmall?.copyWith(
                color: remaining <= 25 ? AppColors.amber : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            LinearProgressIndicator(
              value: remaining / 100,
              semanticsLabel: '${source.name}, còn hạn mức',
              semanticsValue: '${remaining.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Đặt lại ${shortDate(quota.resetsAt)} · ${shortTime(quota.resetsAt)}',
              style: text.bodySmall,
            ),
          ] else
            Text(
              source.id == 'gemini-web'
                  ? 'Có bản nhập hoạt động Gemini web. Xem tần suất trong Phân tích.'
                  : 'Chưa có quota còn hiệu lực để đánh giá.',
              style: text.bodyMedium,
            ),
          const SizedBox(height: AppSpace.lg),
          if (source.totalTokens != null)
            Text(
              '${compactTokens(source.totalTokens)} · ${source.tokenLabel}',
              style: text.bodySmall,
            ),
          if (source.models.isNotEmpty)
            Text(
              '${source.models.length} model có ghi nhận · lịch sử local 30 ngày',
              style: text.bodySmall,
            ),
          if (source.id == 'antigravity')
            Text(
              '${source.windows.length} cửa sổ quota · token IDE chưa có nguồn',
              style: text.bodySmall,
            ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.insights_outlined),
              label: Text(
                'Phân tích ${source.id == 'codex' ? 'Codex' : source.name}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
