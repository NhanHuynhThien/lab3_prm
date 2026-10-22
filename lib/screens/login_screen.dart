import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/login_backdrop.dart';

/// BeeWise's centered brand / welcome / entry-card composition, using Lab3 tokens.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final action = ref.watch(authActionProvider);
    final ready = session.hasValue && !session.hasError && !session.isLoading;
    final unavailable =
        ref.watch(authServiceProvider) is UnavailableAuthService;
    final failure =
        action.failure ??
        (session.error is AuthFailure ? session.error as AuthFailure : null);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: LoginBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (box.maxHeight - 48).clamp(0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: AppMotion.duration(context, AppMotion.medium),
                        curve: AppMotion.curve,
                        builder: (_, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BrandMark(size: 80),
                            const SizedBox(height: AppSpace.lg),
                            Text('TokenLedger', style: text.displaySmall),
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              'Chào mừng bạn quay lại',
                              style: text.bodyLarge,
                            ),
                            const SizedBox(height: AppSpace.xxl),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpace.xl),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(
                                  AppSpace.cardRadius,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0C006C49),
                                    blurRadius: 28,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      'Đăng nhập',
                                      textAlign: TextAlign.center,
                                      style: text.headlineSmall,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  Text(
                                    'Một nơi để hiểu mức sử dụng AI của bạn.',
                                    textAlign: TextAlign.center,
                                    style: text.bodyMedium,
                                  ),
                                  const SizedBox(height: AppSpace.xl),
                                  const _Benefit(
                                    Icons.insights_outlined,
                                    'Số liệu rõ ràng',
                                    'Token, hạn mức và model theo từng nguồn.',
                                  ),
                                  const SizedBox(height: AppSpace.lg),
                                  const _Benefit(
                                    Icons.cloud_done_outlined,
                                    'Không gian của riêng bạn',
                                    'Sổ ghi nhận đồng bộ theo tài khoản Google.',
                                  ),
                                  const SizedBox(height: AppSpace.xl),
                                  if (failure != null) ...[
                                    Semantics(
                                      liveRegion: true,
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          AppSpace.md,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: AppSpace.lg,
                                        ),
                                        decoration: BoxDecoration(
                                          color: failure.isCancellation
                                              ? AppColors.frame
                                              : AppColors.error,
                                          borderRadius: BorderRadius.circular(
                                            AppSpace.controlRadius,
                                          ),
                                        ),
                                        child: Text(
                                          failure.message,
                                          style: TextStyle(
                                            color: failure.isCancellation
                                                ? AppColors.muted
                                                : AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  GoogleSignInButton(
                                    working: action.working,
                                    onPressed:
                                        ready && !action.working && !unavailable
                                        ? () => ref
                                              .read(authActionProvider.notifier)
                                              .signIn()
                                        : null,
                                  ),
                                  if (unavailable)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: Text(
                                        'Google Sign-In chưa được cấu hình.',
                                      ),
                                    ),
                                  if (session.hasError && !action.working)
                                    TextButton.icon(
                                      onPressed: () => ref
                                          .read(authActionProvider.notifier)
                                          .retryConnection(),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Thử kết nối lại'),
                                    ),
                                  if (session.isLoading)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: Text(
                                        'Đang chuẩn bị đăng nhập...',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.xl),
                            Text(
                              'Dữ liệu của bạn được lưu riêng theo tài khoản.\nKết nối nguồn AI sau khi đăng nhập.',
                              textAlign: TextAlign.center,
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.title, this.description);
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      const SizedBox(width: AppSpace.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpace.xs),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}
