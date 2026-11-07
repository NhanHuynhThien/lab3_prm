import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cloud_ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import '../widgets/product_feature_panel.dart';
import 'accounts_screen.dart';
import 'provider_connections_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.user});
  final AuthUser? user;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _permissionWorking = false;
  @override
  Widget build(BuildContext context) {
    ref.watch(notificationListProvider);
    final user = widget.user;
    final sync = ref.watch(cloudSyncProvider);
    final action = ref.watch(authActionProvider);
    final photo = Uri.tryParse(user?.photoUrl ?? '');
    final notificationService = ref.watch(notificationServiceProvider);
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        const PageHeading(
          'Cá nhân',
          'App cá nhân · tài khoản, nguồn dữ liệu và báo cáo của riêng bạn.',
        ),
        Panel(
          child: Row(
            children: [
              if (user != null && photo?.scheme == 'https')
                ClipOval(
                  child: Image.network(
                    user.photoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const BrandMark(size: 56),
                  ),
                )
              else
                const BrandMark(size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Tài khoản Google',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Google chưa cung cấp email',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    const StatusTag('Đã đăng nhập Google'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Kết nối dữ liệu'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.cloud_done_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Sổ ghi nhận của bạn'),
                subtitle: const Text('Lưu riêng theo tài khoản Google'),
                trailing: StatusTag(sync.label, neutral: !sync.confirmed),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.layers_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Tài khoản tự ghi'),
                subtitle: const Text(
                  'Thêm, sửa, lưu trữ và đặt giới hạn token',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(),
                      body: const AccountsScreen(),
                    ),
                  ),
                ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.hub_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Nguồn AI'),
                subtitle: const Text('Codex, Claude, Gemini và Antigravity'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ProviderConnectionsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Thông báo'),
              const Text(
                'Bật để nhận cảnh báo trên điện thoại khi chạm giới hạn token.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _permissionWorking ||
                          (notificationService.permissionGranted &&
                              (!notificationService.backendAvailable ||
                                  notificationService.registered))
                      ? null
                      : () async {
                          setState(() => _permissionWorking = true);
                          final granted = await ref
                              .read(productFeaturesProvider.notifier)
                              .requestNotifications();
                          if (!context.mounted) return;
                          setState(() => _permissionWorking = false);
                          showMessage(
                            context,
                            granted ? 'Đã bật thông báo.' : 'Chưa bật thông báo. Bạn có thể đổi trong cài đặt thiết bị.',
                          );
                        },
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(
                    _permissionWorking
                        ? 'Đang xử lý...'
                        : notificationService.permissionGranted &&
                              notificationService.registered
                        ? 'Thông báo đã bật'
                        : notificationService.permissionGranted &&
                              notificationService.backendAvailable
                        ? 'Kết nối lại thông báo'
                        : 'Bật thông báo',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const ProductFeaturePanel(),
        const SizedBox(height: 24),
        if (action.failure != null)
          Text(
            action.failure!.message,
            style: const TextStyle(color: AppColors.danger),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: action.working
                ? null
                : () => ref.read(authActionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(
              action.working ? 'Đang đăng xuất...' : 'Đăng xuất Google',
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'TokenLedger',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
