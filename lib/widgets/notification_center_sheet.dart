import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/product_features_viewmodel.dart';

class NotificationCenterSheet extends ConsumerWidget {
  const NotificationCenterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationCenterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationListProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    final items = notificationsAsync.asData?.value ?? notificationService.items;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpace.cardRadius),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpace.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'Trung tâm thông báo',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (items.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        notificationService.markAllAsRead();
                      },
                      child: const Text('Đọc tất cả'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: AppSpace.lg,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      size: 48,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: AppSpace.md),
                    const Text(
                      'Chưa có thông báo nào',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    const Text(
                      'Các cảnh báo ngân sách và tin nhắn hệ thống qua FCM sẽ xuất hiện tại đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(productFeaturesProvider.notifier)
                            .sendDemoNotification();
                      },
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Gửi thông báo thử nghiệm'),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      onTap: () {
                        notificationService.markAsRead(item.id);
                        if (item.route != null && item.route!.isNotEmpty) {
                          Navigator.pop(context);
                          // Route navigation can be processed here if applicable
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor: item.isRead
                            ? AppColors.frame
                            : AppColors.soft,
                        child: Icon(
                          Icons.notifications_active,
                          size: 20,
                          color: item.isRead
                              ? AppColors.muted
                              : AppColors.primary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(item.body),
                          const SizedBox(height: 4),
                          Text(
                            '${shortDate(item.receivedAt)} ${shortTime(item.receivedAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(productFeaturesProvider.notifier)
                          .sendDemoNotification();
                    },
                    icon: const Icon(Icons.add_alert_outlined, size: 18),
                    label: const Text('Thêm thông báo mẫu'),
                  ),
                  if (items.isNotEmpty)
                    TextButton(
                      onPressed: () => notificationService.clearAll(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Xóa tất cả'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
