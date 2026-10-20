import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: LayoutBuilder(
              builder: (context, c) {
                final intro = Panel(
                  color: AppColors.soft,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandLockup(),
                      const SizedBox(height: 48),
                      Text(
                        'Mỗi token,\nmột việc rõ ràng.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Biết AI đang giúp bạn làm gì.\nTheo dõi sử dụng, chi phí và hạn mức trong cùng một nơi.',
                      ),
                      const SizedBox(height: 40),
                      const _Feature(
                        Icons.account_balance_wallet_outlined,
                        'Nhiều tài khoản, một góc nhìn',
                      ),
                      const SizedBox(height: 20),
                      const _Feature(
                        Icons.donut_large_rounded,
                        'Chi phí gắn với từng công việc',
                      ),
                      const SizedBox(height: 20),
                      const _Feature(
                        Icons.timelapse_rounded,
                        'Hạn mức có nguồn và thời điểm',
                      ),
                    ],
                  ),
                );
                final entry = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Không gian AI của bạn',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bắt đầu khám phá TokenLedger với dữ liệu mẫu có thể chỉnh sửa.',
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            ref.read(demoSessionProvider.notifier).enter(),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Mở không gian demo'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Google Sign-In · Chưa kết nối'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Demo được lưu trên trình duyệt hoặc thiết bị này. Firebase và đăng nhập Google đang pending.',
                      style: TextStyle(color: AppColors.muted, height: 1.6),
                    ),
                  ],
                );
                return c.maxWidth >= 760
                    ? Row(
                        children: [
                          Expanded(child: intro),
                          const SizedBox(width: 64),
                          Expanded(child: entry),
                        ],
                      )
                    : Column(
                        children: [intro, const SizedBox(height: 32), entry],
                      );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}
