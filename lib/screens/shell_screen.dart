import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import '../widgets/desktop_sidebar.dart';
import '../widgets/storage_recovery.dart';
import 'accounts_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, this.user, this.onOpenDemo, this.onLeaveDemo});

  final AuthUser? user;
  final VoidCallback? onOpenDemo, onLeaveDemo;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  static const _screenNames = ['overview', 'accounts', 'analytics', 'profile'];
  static const labels = ['Tổng quan', 'Tài khoản AI', 'Phân tích', 'Cá nhân'];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.layers_outlined,
    Icons.donut_large_outlined,
    Icons.person_outline_rounded,
  ];

  late final AnimationController _tabFade = AnimationController(
    vsync: this,
    value: 1,
    duration: AppMotion.medium,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(productFeaturesProvider.notifier).screen(_screenNames[_index]);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _tabFade.stop();
      _tabFade.value = 1;
    }
  }

  @override
  void dispose() {
    _tabFade.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    ref.read(productFeaturesProvider.notifier).screen(_screenNames[index]);
    _tabFade.duration = AppMotion.duration(context, AppMotion.short);
    if (MediaQuery.disableAnimationsOf(context)) {
      _tabFade.value = 1;
    } else {
      _tabFade.forward(from: .65);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (isReady, hasError, error) = ref.watch(
      ledgerProvider.select(
        (s) => (s.hasValue && !s.isLoading, s.hasError, s.error),
      ),
    );
    final restored = widget.user == null
        ? null
        : ref.watch(authSessionProvider.select((s) => s.asData?.value));
    final user = restored?.uid == widget.user?.uid ? restored : widget.user;
    final wide = MediaQuery.sizeOf(context).width >= AppSpace.wide;

    Widget guarded(Widget child) => isReady
        ? RepaintBoundary(child: child)
        : hasError
        ? Center(child: StorageRecovery(error: error!))
        : const LoadingFeedback();

    final page = IndexedStack(
      index: _index,
      children: [
        guarded(
          DashboardScreen(
            onAccounts: () => _selectTab(1),
            onAnalytics: () => _selectTab(2),
          ),
        ),
        guarded(const AccountsScreen()),
        guarded(const AnalyticsScreen()),
        RepaintBoundary(
          child: ProfileScreen(
            user: user,
            onOpenDemo: widget.onOpenDemo,
            onLeaveDemo: widget.onLeaveDemo,
          ),
        ),
      ],
    );

    final content = FadeTransition(
      key: const ValueKey('tab-transition'),
      opacity: _tabFade.drive(CurveTween(curve: AppMotion.curve)),
      child: page,
    );

    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  DesktopSidebar(
                    selectedIndex: _index,
                    onSelectTab: _selectTab,
                    labels: labels,
                    icons: icons,
                    user: widget.user,
                  ),
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
                              StatusTag(
                                widget.user == null
                                    ? 'Demo local'
                                    : 'Firestore',
                                neutral: true,
                              ),
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
}
