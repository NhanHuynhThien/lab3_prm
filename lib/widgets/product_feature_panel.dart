import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_features.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'product_feature_cards.dart';
import 'crash_diagnostics_panel.dart';

class ProductFeaturePanel extends ConsumerWidget {
  const ProductFeaturePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationListProvider);
    final config = ref.watch(productConfigProvider);
    final analytics =
        ref.watch(analyticsStatusProvider).asData?.value ??
        const AnalyticsStatus();
    final reports =
        ref.watch(reportsListProvider).asData?.value ??
        ref.watch(reportManagementServiceProvider).reports;

    return Column(
      children: [
        // Panel 1: Remote Config & Analytics. Kept for evidence, not daily use.
        Panel(
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              'Thông tin kỹ thuật',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: [
              Text(
                'Phiên gần đây: ${config.recentLimit} · nguồn ${config.recentSource}',
                key: const ValueKey('config-recent-value'),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Cảnh báo ngân sách: ${config.warningPercent}% · nguồn ${config.warningSource}',
                key: const ValueKey('config-warning-value'),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                config.fetchedAt == null
                    ? 'Chưa có lần lấy cấu hình thành công trong phiên app này.'
                    : 'Kiểm tra cấu hình: ${shortDate(config.fetchedAt!)} lúc ${shortTime(config.fetchedAt!)}',
              ),
              if (config.error != null) ...[
                const SizedBox(height: AppSpace.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    config.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('refresh-product-config'),
                  onPressed: config.refreshing
                      ? null
                      : () async {
                          final success = await ref
                              .read(productFeaturesProvider.notifier)
                              .refreshConfig();
                          if (context.mounted) {
                            showMessage(
                              context,
                              success ? 'Đã lấy cấu hình khả dụng.' : 'Chưa lấy được cấu hình. Giá trị cũ được giữ.',
                            );
                          }
                        },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    config.refreshing
                        ? 'Đang lấy cấu hình...'
                        : 'Làm mới cấu hình',
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              const Divider(),
              const SizedBox(height: AppSpace.sm),
              Text(
                analytics.error ??
                    (analytics.enabled
                        ? 'Analytics SDK: Sẵn sàng ghi nhận sự kiện.'
                        : 'Analytics: Chưa sẵn sàng.'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (analytics.lastEvent != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Sự kiện SDK nhận gần nhất: ${analytics.lastEvent}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),

        // Panel 4: Local PDF Export
        ProductPdfStorageCard(reports: reports),
        const SizedBox(height: AppSpace.lg),
        const CrashDiagnosticsPanel(),
      ],
    );
  }
}
