import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final action = ref.watch(authActionProvider);
    final ready = session.hasValue && !session.hasError && !session.isLoading;
    final failure =
        action.failure ??
        (session.error is AuthFailure ? session.error as AuthFailure : null);
    final unavailable =
        ref.watch(authServiceProvider) is UnavailableAuthService;
    return Scaffold(
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
                        'Đăng nhập để quản lý tài khoản AI và đồng bộ dữ liệu của bạn.',
                      ),
                      const SizedBox(height: 28),
                      GoogleSignInButton(
                        working: action.working,
                        onPressed: ready && !action.working && !unavailable
                            ? () =>
                                  ref.read(authActionProvider.notifier).signIn()
                            : null,
                      ),
                      if (unavailable) ...[
                        const SizedBox(height: 12),
                        const Text('Google Sign-In chưa được cấu hình.'),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: action.working
                              ? null
                              : () => ref
                                    .read(demoSessionProvider.notifier)
                                    .enter(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Mở không gian demo'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (failure != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            failure.message,
                            style: TextStyle(
                              color: failure.isCancellation
                                  ? AppColors.muted
                                  : AppColors.danger,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (session.hasError && !action.working)
                        OutlinedButton.icon(
                          onPressed: () => ref
                              .read(authActionProvider.notifier)
                              .retryConnection(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử kết nối lại'),
                        ),
                      if (session.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('Đang chuẩn bị đăng nhập...'),
                        ),
                      const Text(
                        'Demo chỉ lưu trên thiết bị này, tách biệt với tài khoản Google và không tự tải dữ liệu lên cloud.',
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
