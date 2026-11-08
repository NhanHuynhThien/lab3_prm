import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cloud_ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import '../widgets/product_feature_cards.dart';
import '../widgets/product_feature_panel.dart';
import '../widgets/settings_group.dart';
import 'provider_connections_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.user});
  final AuthUser? user;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _permissionWorking = false;

  Future<void> _enableNotifications() async {
    setState(() => _permissionWorking = true);
    final granted = await ref
        .read(productFeaturesProvider.notifier)
        .requestNotifications();
    if (!mounted) return;
    setState(() => _permissionWorking = false);
    showMessage(
      context,
      granted
          ? 'Đã bật thông báo.'
          : 'Chưa bật thông báo. Bạn có thể đổi trong cài đặt thiết bị.',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationListProvider);
    final user = widget.user;
    final sync = ref.watch(cloudSyncProvider);
    final action = ref.watch(authActionProvider);
    final photo = Uri.tryParse(user?.photoUrl ?? '');
    final notifications = ref.watch(notificationServiceProvider);
    final notificationsOn =
        notifications.permissionGranted &&
        (!notifications.backendAvailable || notifications.registered);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        const PageHeading('Cá nhân', null),
        SettingsGroup(
          title: 'Tài khoản',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Row(
                children: [
                  if (user != null && photo?.scheme == 'https')
                    ClipOval(
                      child: Image.network(
                        user.photoUrl!,
                        width: AppSpace.avatar,
                        height: AppSpace.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const BrandMark(size: AppSpace.avatar),
                      ),
                    )
                  else
                    const BrandMark(size: AppSpace.avatar),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Tài khoản Google',
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          user?.email ?? 'Google chưa cung cấp email',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SettingsTile(
              icon: Icons.logout,
              title: action.working ? 'Đang đăng xuất...' : 'Đăng xuất Google',
              subtitle: action.failure?.message,
              destructive: true,
              onTap: action.working
                  ? null
                  : () => ref.read(authActionProvider.notifier).signOut(),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Dữ liệu',
          children: [
            SettingsTile(
              icon: Icons.cloud_done_outlined,
              title: 'Sổ ghi nhận của bạn',
              subtitle: 'Lưu riêng theo tài khoản Google',
              trailing: StatusTag(sync.label, neutral: !sync.confirmed),
            ),
            SettingsTile(
              icon: Icons.hub_outlined,
              title: 'Nguồn AI',
              subtitle: 'Codex, Claude, Gemini và Antigravity',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ProviderConnectionsScreen(),
                ),
              ),
            ),
            const ExportedReports(),
          ],
        ),
        SettingsGroup(
          title: 'Thông báo',
          children: [
            SettingsTile(
              icon: notificationsOn
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_outlined,
              title: _permissionWorking
                  ? 'Đang xử lý...'
                  : notifications.permissionGranted && notifications.registered
                  ? 'Thông báo đã bật'
                  : notifications.permissionGranted &&
                        notifications.backendAvailable
                  ? 'Kết nối lại thông báo'
                  : 'Bật thông báo',
              subtitle: notificationsOn
                  ? 'Máy này nhận cảnh báo giới hạn token và thông báo từ TokenLedger.'
                  : 'Nhận cảnh báo khi chạm giới hạn token đã đặt và thông báo từ TokenLedger.',
              trailing: notificationsOn
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: _permissionWorking || notificationsOn
                  ? null
                  : _enableNotifications,
            ),
          ],
        ),
        const DiagnosticsGroup(),
      ],
    );
  }
}
