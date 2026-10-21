import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../models/auth_session.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/cloud_ledger_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import '../widgets/product_feature_panel.dart';
import '../viewmodels/product_features_viewmodel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.user,
    this.onOpenDemo,
    this.onLeaveDemo,
  });
  final AuthUser? user;
  final VoidCallback? onOpenDemo, onLeaveDemo;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _working = false;
  Future<void> _reset(bool empty) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      if (!await confirmAction(
            context,
            empty ? 'Xóa dữ liệu demo?' : 'Khôi phục dữ liệu mẫu?',
            'Chỉ dữ liệu được gắn nhãn demo sẽ được ${empty ? 'xóa' : 'thay bằng dữ liệu mẫu'}. Dữ liệu nhập tay và dữ liệu cũ chưa phân loại được giữ nguyên. Thao tác không thể hoàn tác.',
          ) ||
          !mounted) {
        return;
      }
      final vm = ref.read(ledgerProvider.notifier);
      if (empty) {
        await vm.clearDemo();
      } else {
        await vm.resetDemo();
      }
      if (mounted) {
        showMessage(
          context,
          empty ? 'Đã xóa dữ liệu demo.' : 'Đã khôi phục dữ liệu mẫu.',
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final cloud = user != null && ref.watch(cloudOwnerProvider) != null;
    final sync = cloud ? ref.watch(cloudSyncProvider) : null;
    final config = ref.watch(productConfigProvider);
    final analytics = ref.watch(analyticsStatusProvider).asData?.value;
    final authAction = user == null
        ? const AuthActionState()
        : ref.watch(authActionProvider);
    final photo = Uri.tryParse(user?.photoUrl ?? '');
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        PageHeading(
          'Cá nhân',
          user == null
              ? 'Không gian demo và trạng thái các kết nối.'
              : 'Tài khoản Google và trạng thái kết nối dữ liệu.',
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
                      user == null
                          ? 'Không gian demo'
                          : (user.displayName?.trim().isNotEmpty ?? false)
                          ? user.displayName!
                          : 'Tài khoản Google',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user == null
                          ? 'Chưa đăng nhập Google trong không gian này'
                          : user.email ?? 'Google chưa cung cấp email',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusTag(
                user == null ? 'Local' : 'Google',
                neutral: user == null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Kết nối Firebase'),
              Text(
                user == null
                    ? 'Bạn đang ở sandbox local. Dữ liệu tại đây không tự đưa vào tài khoản Google hoặc Firestore.'
                    : 'Dữ liệu cá nhân lưu riêng trên Firestore. Token, chi phí và quota do bạn nhập tay; demo local ở không gian riêng.',
              ),
              const SizedBox(height: 16),
              ...[
                'Google Sign-In',
                'Cloud Firestore',
                'Thông báo FCM',
                'Remote Config',
                'Analytics',
                'Crashlytics',
                'Export PDF & cloud storage',
              ].map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(s)),
                      StatusTag(
                        s == 'Google Sign-In' && user != null
                            ? 'Đã kết nối'
                            : s == 'Cloud Firestore' && sync != null
                            ? sync.label
                            : s == 'Remote Config' && cloud
                            ? config.refreshing
                                  ? 'Đang lấy'
                                  : config.error != null
                                  ? 'Lỗi lấy mới'
                                  : 'Có giá trị'
                            : s == 'Analytics' && cloud
                            ? analytics?.enabled == true
                                  ? 'SDK sẵn sàng'
                                  : 'Chưa sẵn sàng'
                            : 'Chưa nối',
                        neutral:
                            !(s == 'Google Sign-In' && user != null ||
                                s == 'Cloud Firestore' &&
                                    sync?.confirmed == true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (cloud) ...[
          const ProductFeaturePanel(),
          const SizedBox(height: AppSpace.xl),
        ],
        if (user == null)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Dữ liệu demo trên thiết bị'),
                const Text(
                  'Dữ liệu mẫu chỉ để kiểm tra giao diện và nghiệp vụ. Số token, chi phí và quota không được đồng bộ từ Claude, Codex hay Gemini.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _working ? null : () => _reset(false),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Khôi phục dữ liệu mẫu'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: _working ? null : () => _reset(true),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa dữ liệu demo'),
                    ),
                  ],
                ),
                if (_working)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Semantics(
                      liveRegion: true,
                      label: 'Đang cập nhật dữ liệu local',
                      excludeSemantics: true,
                      child: LinearProgressIndicator(
                        value: MediaQuery.disableAnimationsOf(context)
                            ? .5
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (user != null) ...[
          if (authAction.failure != null)
            Semantics(
              liveRegion: true,
              child: Text(
                authAction.failure!.message,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          OutlinedButton.icon(
            onPressed: authAction.working
                ? null
                : () => ref.read(authActionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(
              authAction.working ? 'Đang đăng xuất...' : 'Đăng xuất Google',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: authAction.working
                ? null
                : widget.onOpenDemo ??
                      () => ref.read(demoSessionProvider.notifier).enter(),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Mở demo local riêng biệt'),
          ),
        ],
        if (user == null)
          OutlinedButton.icon(
            onPressed: _working
                ? null
                : widget.onLeaveDemo ??
                      () => ref.read(demoSessionProvider.notifier).leave(),
            icon: const Icon(Icons.logout),
            label: const Text('Thoát không gian demo'),
          ),
        const SizedBox(height: 24),
        Text(
          'TokenLedger · PRM393 Lab 3\nCore UI kế thừa StudentPay Lab 2.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
