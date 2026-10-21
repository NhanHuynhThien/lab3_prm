import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/login_screen.dart';
import '../screens/shell_screen.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../services/cloud_ledger_repository.dart';
import '../services/ledger_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cloud_ledger_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'cloud_sync_banner.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(featureSessionProvider);
    // Explicit local sandbox: neither initializes Auth nor exposes cloud data.
    if (ref.watch(demoSessionProvider)) {
      return _WorkspaceScope(
        key: ValueKey('demo-local'),
        auth: ref.read(authServiceProvider),
        parent: ProviderScope.containerOf(context),
        clock: ref.read(clockProvider),
        local: ref.read(ledgerRepositoryProvider),
        factory: ref.read(cloudRepositoryFactoryProvider),
        leaveDemo: () => ref.read(demoSessionProvider.notifier).leave(),
      );
    }
    final session = ref.watch(authSessionProvider);
    if (session.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: LoadingFeedback(label: 'Đang kiểm tra đăng nhập'),
        ),
      );
    }
    final user = session.asData?.value;
    if (user != null && !session.hasError) {
      return _WorkspaceScope(
        key: ValueKey('firebase-${user.uid}'),
        user: user,
        auth: ref.read(authServiceProvider),
        parent: ProviderScope.containerOf(context),
        clock: ref.read(clockProvider),
        factory: ref.read(cloudRepositoryFactoryProvider),
        openDemo: () => ref.read(demoSessionProvider.notifier).enter(),
      );
    }
    return const _SessionNavigator(
      key: ValueKey('signed-out'),
      home: LoginScreen(),
    );
  }
}

/// All pushed pages belong to this session. Logout/UID change disposes its
/// entire route stack, including forms and their controllers, rather than only
/// replacing the page underneath old routes.
class _SessionNavigator extends StatefulWidget {
  const _SessionNavigator({super.key, required this.home});
  final Widget home;
  @override
  State<_SessionNavigator> createState() => _SessionNavigatorState();
}

class _SessionNavigatorState extends State<_SessionNavigator> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler(
    onPopWithResult: (result) => _navigator.currentState?.pop(result),
    child: Navigator(
      key: _navigator,
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => widget.home),
    ),
  );
}

/// Independent container for ALL workspace providers, projections and drafts.
/// Sharing only service boundaries avoids accidentally inheriting cached local
/// projections or filters through an incompletely scoped provider dependency.
class _WorkspaceScope extends StatefulWidget {
  const _WorkspaceScope({
    super.key,
    this.user,
    required this.auth,
    required this.parent,
    required this.clock,
    required this.factory,
    this.local,
    this.openDemo,
    this.leaveDemo,
  });
  final AuthUser? user;
  final AuthService auth;
  final ProviderContainer parent;
  final DateTime Function() clock;
  final LedgerRepository? local;
  final CloudLedgerRepository Function() factory;
  final VoidCallback? openDemo, leaveDemo;
  @override
  State<_WorkspaceScope> createState() => _WorkspaceScopeState();
}

class _WorkspaceScopeState extends State<_WorkspaceScope> {
  late final _container = ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(widget.auth),
      if (widget.user != null) ...[
        analyticsServiceProvider.overrideWithValue(
          widget.parent.read(analyticsServiceProvider),
        ),
        remoteConfigServiceProvider.overrideWithValue(
          widget.parent.read(remoteConfigServiceProvider),
        ),
      ],
      authActionProvider.overrideWith(
        () => _WorkspaceAuthActions(widget.parent),
      ),
      clockProvider.overrideWithValue(widget.clock),
      cloudOwnerProvider.overrideWithValue(widget.user?.uid),
      cloudRepositoryFactoryProvider.overrideWithValue(widget.factory),
      if (widget.local != null)
        ledgerRepositoryProvider.overrideWithValue(widget.local!),
      if (widget.user != null)
        ledgerProvider.overrideWith(CloudLedgerViewModel.new),
    ],
  );
  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = _SessionNavigator(
      home: ShellScreen(
        user: widget.user,
        onOpenDemo: widget.openDemo,
        onLeaveDemo: widget.leaveDemo,
      ),
    );
    return UncontrolledProviderScope(
      container: _container,
      child: widget.user == null
          ? navigator
          : Material(
              child: SafeArea(
                child: Column(
                  children: [
                    const CloudSyncBanner(),
                    Expanded(child: navigator),
                  ],
                ),
              ),
            ),
    );
  }
}

/// One action coordinator across root login and workspace logout buttons.
class _WorkspaceAuthActions extends AuthViewModel {
  _WorkspaceAuthActions(this.parent);
  final ProviderContainer parent;
  @override
  AuthActionState build() {
    final subscription = parent.listen(authActionProvider, (_, next) {
      if (ref.mounted) state = next;
    });
    ref.onDispose(subscription.close);
    return parent.read(authActionProvider);
  }

  @override
  Future<void> signIn() => parent.read(authActionProvider.notifier).signIn();
  @override
  Future<void> signOut() => parent.read(authActionProvider.notifier).signOut();
}
