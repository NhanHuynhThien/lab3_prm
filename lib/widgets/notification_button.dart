import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/product_features_viewmodel.dart';
import 'notification_center_sheet.dart';

class NotificationButton extends ConsumerWidget {
  const NotificationButton({super.key, this.style});
  final ButtonStyle? style;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return IconButton(
      tooltip: 'Thông báo',
      style: style,
      onPressed: () => NotificationCenterSheet.show(context),
      icon: unread > 0
          ? Badge(
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
    );
  }
}
