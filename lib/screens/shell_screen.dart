import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import '../viewmodels/token_limit_viewmodel.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/desktop_sidebar.dart';
import '../widgets/notification_button.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'review_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, this.user});

  final AuthUser? user;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  final _visited = <int>{0};
  AuthUser? _profileUser;
  StreamSubscription<String>? _notificationRoute;
  late final _pages = <Widget>[
    RepaintBoundary(child: DashboardScreen(onAnalytics: () => _selectTab(2))),
    RepaintBoundary(child: ReviewScreen(onAnalytics: () => _selectTab(2))),
    const RepaintBoundary(child: AnalyticsScreen()),
    RepaintBoundary(child: ProfileScreen(user: widget.user)),
  ];

  static const _screenNames = ['overview', 'review', 'analytics', 'profile'];
  static const labels = ['Tổng quan', 'Đánh giá', 'Phân tích', 'Cá nhân'];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.fact_check_outlined,
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
    final notifications = ref.read(notificationServiceProvider);
    void open(String route) {
      if (!mounted) return;
      // Accounts now live under Profile.
      final index = switch (route) {
        '/overview' => 0,
        '/analytics' => 2,
        '/profile' || '/accounts' => 3,
        _ => -1,
      };
      if (index >= 0) _selectTab(index);
      notifications.takePendingRoute();
    }

    _notificationRoute = notifications.onTargetRouteRequested.listen(open);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(productFeaturesProvider.notifier).screen(_screenNames[_index]);
        final pending = notifications.takePendingRoute();
        if (pending != null) open(pending);
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
    unawaited(_notificationRoute?.cancel());
    super.dispose();
  }

  void _selectTab(int index) {
    if (_index == index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
    ref.read(productFeaturesProvider.notifier).screen(_screenNames[index]);
    _tabFade.duration = AppMotion.duration(context, AppMotion.short);
    if (MediaQuery.disableAnimationsOf(context)) {
      _tabFade.value = 1;
    } else {
      _tabFade.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restored = widget.user == null
        ? null
        : ref.watch(authSessionProvider.select((s) => s.asData?.value));
    final user = restored?.uid == widget.user?.uid ? restored : widget.user;
    ref.watch(tokenAlertWatcherProvider);
    final wide = MediaQuery.sizeOf(context).width >= AppSpace.wide;

    if (_profileUser != user) {
      _profileUser = user;
      _pages[3] = RepaintBoundary(child: ProfileScreen(user: user));
    }
    final page = Stack(
      fit: StackFit.expand,
      children: [
        for (final i in _visited)
          Offstage(
            key: ValueKey('workspace-tab-$i'),
            offstage: i != _index,
            child: TickerMode(enabled: i == _index, child: _pages[i]),
          ),
      ],
    );

    final content = FadeTransition(
      key: const ValueKey('tab-transition'),
      opacity: _tabFade.drive(
        Tween<double>(
          begin: .92,
          end: 1,
        ).chain(CurveTween(curve: AppMotion.curve)),
      ),
      child: SlideTransition(
        position: _tabFade.drive(
          Tween<Offset>(
            begin: const Offset(0, .012),
            end: Offset.zero,
          ).chain(CurveTween(curve: AppMotion.curve)),
        ),
        child: page,
      ),
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
                              const Spacer(),
                              const NotificationButton(),
                              const SizedBox(width: 8),
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
                  AppTopBar(
                    onHistory: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const HistoryScreen(),
                      ),
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
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
              ],
            ),
    );
  }
}
