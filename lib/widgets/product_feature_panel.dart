import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_features.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';

class ProductFeaturePanel extends ConsumerWidget {
  const ProductFeaturePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(productConfigProvider);
    final analytics =
        ref.watch(analyticsStatusProvider).asData?.value ??
        const AnalyticsStatus();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Cấu hình và đo lường'),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          OutlinedButton.icon(
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
                        success
                            ? 'Đã lấy cấu hình khả dụng.'
                            : 'Chưa lấy được cấu hình. Giá trị cũ được giữ.',
                      );
                    }
                  },
            icon: const Icon(Icons.refresh),
            label: Text(
              config.refreshing ? 'Đang lấy cấu hình...' : 'Làm mới cấu hình',
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            analytics.error ??
                (analytics.enabled
                    ? 'Analytics SDK đã sẵn sàng.'
                    : 'Analytics chưa sẵn sàng.'),
          ),
          if (analytics.lastEvent != null)
            Text('Sự kiện SDK nhận gần nhất: ${analytics.lastEvent}'),
          const SizedBox(height: AppSpace.sm),
          const Text(
            'Dữ liệu demo không gửi sự kiện. Chưa xác nhận sự kiện trên DebugView; cần kiểm tra console riêng.',
          ),
        ],
      ),
    );
  }
}
