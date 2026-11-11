import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cloud_ledger_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import '../viewmodels/provider_sources_viewmodel.dart';
import '../widgets/export_report_dialog.dart';
import '../widgets/common.dart';
import '../widgets/data_scope_picker.dart';
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
    final notifications = ref.watch(notificationServiceProvider);
    final notificationsOn =
        notifications.permissionGranted &&
        (!notifications.backendAvailable || notifications.registered);
    final sources = ref
        .watch(providerSourcesProvider)
        .where((s) => s.status == 'ready')
        .map((s) => s.name)
        .toList();
    // Identity (avatar, name) already sits in the header island; this page
    // only holds what the header cannot: sync, settings, reports, sign-out.
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        // No page title: the selected tab already says "Cá nhân", so the
        // first group heading sits right under the header island.
        SettingsGroup(
          title: 'Kết nối',
          children: [
            SettingsTile(
              icon: Icons.cloud_done_outlined,
              title: user?.email ?? 'Tài khoản Google',
              subtitle: 'Sổ ghi nhận lưu riêng theo tài khoản này',
              trailing: StatusTag(sync.label, neutral: !sync.confirmed),
            ),
            SettingsTile(
              icon: Icons.hub_outlined,
              title: 'Companion và nguồn AI',
              subtitle: sources.isEmpty
                  ? 'Chưa nhận dữ liệu. Mở Companion trên máy tính để kết nối.'
                  : 'Đang tự đồng bộ: ${sources.join(', ')}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ProviderConnectionsScreen(),
                ),
              ),
            ),
            SettingsTile(
              icon: Icons.logout,
              title: action.working ? 'Đang đăng xuất...' : 'Đăng xuất',
              subtitle: action.failure?.message,
              destructive: true,
              onTap: action.working
                  ? null
                  : () => ref.read(authActionProvider.notifier).signOut(),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Cài đặt',
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
              subtitle: 'Cảnh báo khi chạm giới hạn token đã đặt.',
              trailing: notificationsOn
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: _permissionWorking || notificationsOn
                  ? null
                  : _enableNotifications,
            ),
            SettingsTile(
              icon: Icons.schedule,
              title: 'Múi giờ báo cáo',
              subtitle:
                  ref.watch(ledgerProvider).asData?.value.reportingTimezone ??
                  'Asia/Ho_Chi_Minh',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ReportingSettingsScreen(),
                ),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Báo cáo',
          children: [
            SettingsTile(
              icon: Icons.file_download_outlined,
              title: 'Xuất báo cáo PDF',
              subtitle: 'Token, phiên, model và hạn mức theo kỳ.',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ExportReportDialog.show(context),
            ),
            const ExportedReports(),
          ],
        ),
        const DiagnosticsGroup(),
      ],
    );
  }
}
