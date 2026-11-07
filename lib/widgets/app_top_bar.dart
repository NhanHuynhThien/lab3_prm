import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_mark.dart';
import 'notification_button.dart';

/// Mobile header: brand on the left, two matching round action buttons on the right.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.onHistory});
  final VoidCallback onHistory;

  static final _buttonStyle = IconButton.styleFrom(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.text,
    fixedSize: const Size.square(AppSpace.touch),
    side: const BorderSide(color: AppColors.line),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.sm,
      AppSpace.lg,
      AppSpace.xs,
    ),
    child: SizedBox(
      height: AppSpace.touch,
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: BrandLockup(compact: true),
            ),
          ),
          NotificationButton(style: _buttonStyle),
          const SizedBox(width: AppSpace.sm),
          IconButton(
            tooltip: 'Lịch sử sử dụng',
            style: _buttonStyle,
            onPressed: onHistory,
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
    ),
  );
}
