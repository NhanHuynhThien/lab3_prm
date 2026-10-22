import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_features.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'notification_center_sheet.dart';
import 'product_feature_cards.dart';

class ProductFeaturePanel extends ConsumerWidget {
  const ProductFeaturePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(productConfigProvider);
    final analytics =
        ref.watch(analyticsStatusProvider).asData?.value ??
        const AnalyticsStatus();
    final crashlytics = ref.watch(crashlyticsStatusProvider).asData?.value;
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
    final reports =
        ref.watch(reportsListProvider).asData?.value ??
        ref.watch(reportManagementServiceProvider).reports;

    return Column(
      children: [
        // Panel 1: Remote Config & Analytics
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                'Cấu hình và đo lường (Remote Config & Analytics)',
              ),
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

        // Panel 2: Crashlytics Diagnostics
        ProductCrashlyticsCard(status: crashlytics),
        const SizedBox(height: AppSpace.lg),

        // Panel 3: Notifications & FCM
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      'Thông báo & FCM',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (unreadNotifications > 0) ...[
                    const SizedBox(width: AppSpace.sm),
                    Badge(
                      label: Text('$unreadNotifications'),
                      child: const Icon(
                        Icons.notifications,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              const Text(
                'Nhận thông báo đẩy từ Firebase Cloud Messaging và quản lý cảnh báo trong ứng dụng.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => NotificationCenterSheet.show(context),
                    icon: const Icon(Icons.inbox_outlined, size: 18),
                    label: Text(
                      unreadNotifications > 0
                          ? 'Xem thông báo ($unreadNotifications)'
                          : 'Xem thông báo',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(productFeaturesProvider.notifier)
                          .sendDemoNotification();
                      showMessage(
                        context,
                        'Đã gửi thông báo mẫu vào danh sách!',
                      );
                    },
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Gửi thông báo mẫu'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),

        // Panel 4: PDF Export & Cloud Storage
        ProductPdfStorageCard(reports: reports),
      ],
    );
  }
}
