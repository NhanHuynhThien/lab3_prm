import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import 'accounts_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});
  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _tabFade = AnimationController(
    vsync: this,
    value: 1,
    duration: AppMotion.medium,
  );
  @override
  void dispose() {
    _tabFade.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    _tabFade.duration = AppMotion.duration(context, AppMotion.short);
    if (MediaQuery.disableAnimationsOf(context)) {
      _tabFade.value = 1;
    } else {
      _tabFade.forward(from: .65);
    }
  }

  static const labels = ['Tổng quan', 'Tài khoản AI', 'Phân tích', 'Cá nhân'];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.layers_outlined,
    Icons.donut_large_outlined,
    Icons.person_outline_rounded,
  ];
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider);
    final wide = MediaQuery.sizeOf(context).width >= AppSpace.wide;
    final page = ledger.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: ErrorFeedback(
          message:
              'Dữ liệu local không đọc được. Không gian hiện tại chưa bị ghi đè. $e',
          retry: () => ref.invalidate(ledgerProvider),
        ),
      ),
      data: (_) => IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            onAccounts: () => _selectTab(1),
            onAnalytics: () => _selectTab(2),
          ),
          const AccountsScreen(),
          const AnalyticsScreen(),
          const ProfileScreen(),
        ],
      ),
    );
    final content = FadeTransition(
      opacity: _tabFade.drive(CurveTween(curve: AppMotion.curve)),
      child: page,
    );
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  _sidebar(context),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Không gian cá nhân',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              const StatusTag('Demo local', neutral: true),
                              const SizedBox(width: 16),
                              IconButton(
                                tooltip: 'Cá nhân & trạng thái kết nối',
                                onPressed: () => _selectTab(3),
                                icon: const Icon(Icons.person_outline_rounded),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(
                              right: 12,
                              bottom: 12,
                            ),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: content,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        const BrandLockup(compact: true),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Lịch sử sử dụng',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.history_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
      ),
      backgroundColor: wide ? AppColors.frame : AppColors.background,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _selectTab,
              destinations: List.generate(
                4,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  label: i == 1 ? 'Tài khoản' : labels[i],
                ),
              ),
            ),
    );
  }

  Widget _sidebar(BuildContext context) => SizedBox(
    width: AppSpace.sidebar,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLockup(),
          const SizedBox(height: 36),
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              'Không gian làm việc',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: _index == i ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectTab(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icons[i],
                          size: 21,
                          color: _index == i
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontWeight: _index == i
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
            icon: const Icon(Icons.history_rounded, size: 20),
            label: const Text('Lịch sử sử dụng'),
          ),
          const Spacer(),
          Panel(
            color: AppColors.soft,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.storage_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(height: 12),
                Text(
                  'Dữ liệu trên thiết bị',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Bạn có thể thêm, sửa và xóa dữ liệu demo. Firebase chưa kết nối.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.disabled,
                child: Icon(Icons.person_outline, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Không gian demo',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      'Local workspace',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
