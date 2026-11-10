import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../theme/app_theme.dart';
import '../viewmodels/cloud_ledger_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'brand_mark.dart';
import 'notification_button.dart';

/// Mobile header island, after the BeeWise LMS composition the user chose:
/// one rounded card with the signed-in identity on the left (avatar with a
/// sync dot, time-of-day greeting and name) and soft round
/// actions on the right. Colours, type and logo stay TokenLedger's own.
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key, required this.onHistory, this.user});
  final VoidCallback onHistory;
  final AuthUser? user;

  static const _avatar = 46.0;
  static const _action = 44.0;

  static final _buttonStyle = IconButton.styleFrom(
    backgroundColor: AppColors.soft,
    foregroundColor: AppColors.primary,
    fixedSize: const Size.square(_action),
    minimumSize: const Size.square(_action),
    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.14)),
  );

  static String greeting(int hour) => hour < 12
      ? 'Chào buổi sáng'
      : hour < 18
      ? 'Chào buổi chiều'
      : 'Chào buổi tối';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = ref.watch(nowProvider.select((now) => now.toLocal().hour));
    final synced = ref.watch(cloudSyncProvider.select((s) => s.confirmed));
    final text = Theme.of(context).textTheme;
    // Google name order varies, so show it whole and let it ellipsize.
    final display = (user?.displayName ?? '').trim();
    final name = display.isEmpty ? 'bạn' : display;
    final photo = Uri.tryParse(user?.photoUrl ?? '');
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.lg,
        AppSpace.sm,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpace.cardRadius),
        border: Border.all(color: AppColors.line),
        boxShadow: AppDecor.cardShadow,
      ),
      child: Row(
        children: [
          _Avatar(
            size: _avatar,
            photoUrl: photo?.scheme == 'https' ? user!.photoUrl : null,
            synced: synced,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting(hour),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          NotificationButton(style: _buttonStyle),
          const SizedBox(width: AppSpace.sm),
          IconButton(
            tooltip: 'Lịch sử sử dụng',
            style: _buttonStyle,
            onPressed: onHistory,
            icon: const Icon(Icons.history_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, required this.synced, this.photoUrl});
  final double size;
  final bool synced;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) => Semantics(
    label: synced ? 'Đã đồng bộ' : 'Đang đồng bộ',
    child: SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 2),
            ),
            child: ClipOval(
              child: photoUrl == null
                  ? BrandMark(size: size)
                  : Image.network(
                      photoUrl!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => BrandMark(size: size),
                    ),
            ),
          ),
          // Sync dot: green once the server confirmed the ledger.
          PositionedDirectional(
            end: -1,
            bottom: -1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: synced ? AppColors.accent : AppColors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
