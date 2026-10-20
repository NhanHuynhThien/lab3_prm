import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _working = false;
  Future<void> _reset(bool empty) async {
    if (!await confirmAction(
      context,
      empty ? 'Xóa dữ liệu demo?' : 'Khôi phục dữ liệu mẫu?',
      'Tất cả tài khoản và phiên trong không gian local này sẽ được ${empty ? 'xóa' : 'thay bằng dữ liệu mẫu'}. Thao tác không thể hoàn tác.',
    )) {
      return;
    }
    setState(() => _working = true);
    try {
      final vm = ref.read(ledgerProvider.notifier);
      if (empty) {
        await vm.clearDemo();
      } else {
        await vm.resetDemo();
      }
      if (mounted) {
        showMessage(
          context,
          empty ? 'Đã xóa dữ liệu local.' : 'Đã khôi phục dữ liệu mẫu.',
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
    children: [
      const PageHeading(
        'Cá nhân',
        'Không gian demo và trạng thái các kết nối.',
      ),
      Panel(
        child: Row(
          children: [
            const BrandMark(size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Không gian demo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chưa đăng nhập Google',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const StatusTag('Local', neutral: true),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Kết nối Firebase'),
            const Text(
              'Firebase đang pending theo yêu cầu. Bản này không gọi Firebase hoặc thu thập Analytics.',
            ),
            const SizedBox(height: 16),
            ...[
              'Google Sign-In',
              'Cloud Firestore',
              'Thông báo FCM',
              'Remote Config',
              'Crashlytics & Analytics',
              'Export PDF & cloud storage',
            ].map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(s)),
                    const StatusTag('Pending', neutral: true),
                  ],
                ),
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
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: () => ref.read(demoSessionProvider.notifier).leave(),
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
