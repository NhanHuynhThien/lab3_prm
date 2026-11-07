import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_dashboard.dart';
import '../models/provider_analysis.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/provider_sources_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../viewmodels/token_limit_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/provider_brand_icon.dart';

/// One-page assessment: overall verdict, per-agent health, manual ledger.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, required this.onAnalytics});
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final dashboard = AgentDashboard(ref.watch(providerSourcesProvider), now);
    final alerts = ref.watch(tokenLimitsProvider).length;
    final ledgerReady = ref.watch(ledgerProvider).hasValue;
    final text = Theme.of(context).textTheme;
    final ok = dashboard.attention == 0;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        const PageHeading('Đánh giá', 'Tình trạng sử dụng AI trong một trang.'),
        Panel(
          color: ok ? AppColors.soft : AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ok ? Icons.verified_outlined : Icons.info_outline_rounded,
                    color: ok ? AppColors.primary : AppColors.amber,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      dashboard.connected.isEmpty
                          ? 'Chưa có agent để đánh giá'
                          : ok
                          ? 'Mọi agent đều ổn'
                          : '${dashboard.attention} agent cần chú ý',
                      style: text.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  _Stat('${dashboard.connected.length}', 'Agent theo dõi'),
                  _Stat('${dashboard.attention}', 'Cần chú ý'),
                  _Stat('$alerts', 'Cảnh báo đã đặt'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        if (dashboard.connected.isNotEmpty) ...[
          const SectionTitle('Từng agent'),
          for (final source in dashboard.connected) ...[
            Panel(
              child: Builder(
                builder: (context) {
                  final review = ProviderAnalysis.evaluate(source, now);
                  final quota = dashboard.limiting(source);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProviderBrandIcon(source.id),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(source.name, style: text.titleMedium),
                                Text(
                                  review.title,
                                  style: text.bodyMedium?.copyWith(
                                    color: review.warning
                                        ? AppColors.amber
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (quota != null)
                            Text(
                              '${quota.usedPercent.toStringAsFixed(0)}%',
                              style: text.titleMedium,
                            ),
                        ],
                      ),
                      if (quota != null) ...[
                        const SizedBox(height: AppSpace.sm),
                        AnimatedProgress(value: quota.usedPercent / 100),
                      ],
                      const SizedBox(height: AppSpace.sm),
                      Text(review.message, style: text.bodySmall),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          const SizedBox(height: AppSpace.md),
        ],
        if (ledgerReady) ...[
          const SectionTitle('Sổ tự ghi · kỳ hiện tại'),
          DashboardMetricsCard(
            summary: ref.watch(dashboardProjectionProvider).summary,
          ),
          const SizedBox(height: AppSpace.xl),
        ],
        OutlinedButton.icon(
          onPressed: onAnalytics,
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Xem phân tích chi tiết'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
