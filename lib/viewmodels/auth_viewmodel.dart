import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => const UnavailableAuthService(),
);

final authSessionProvider = StreamProvider<AuthUser?>((ref) async* {
  final service = ref.watch(authServiceProvider);
  try {
    await service.initialize().timeout(const Duration(seconds: 20));
  } on TimeoutException {
    throw const AuthFailure(
      AuthProblem.network,
      'Kết nối đăng nhập mất nhiều thời gian. Hãy kiểm tra mạng và thử lại.',
    );
  }
  yield* service.userChanges;
}, retry: (count, error) => null);

class AuthActionState {
  const AuthActionState({
    this.working = false,
    this.signingOut = false,
    this.failure,
  });
  final bool working, signingOut;
  final AuthFailure? failure;
}

class AuthViewModel extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthActionState();

  Future<void> signIn() => _perform(false);
  Future<void> signOut() => _perform(true);

  Future<void> _perform(bool signingOut) async {
    if (state.working) return;
    final session = ref.read(authSessionProvider);
    if (session.isLoading || session.hasError || !session.hasValue) return;
    final service = ref.read(authServiceProvider);
    state = AuthActionState(working: true, signingOut: signingOut);
    AuthFailure? failure;
    try {
      if (signingOut) {
        await service.signOut();
      } else {
        await service.signInWithGoogle();
      }
    } catch (error) {
      failure = error is AuthFailure
          ? error
          : const AuthFailure(
              AuthProblem.unknown,
              'Chưa hoàn tất thao tác đăng nhập. Hãy thử lại.',
            );
    }
    if (ref.mounted) state = AuthActionState(failure: failure);
  }

  void retryConnection() {
    if (state.working) return;
    state = const AuthActionState();
    ref.invalidate(authSessionProvider);
  }
}

final authActionProvider = NotifierProvider<AuthViewModel, AuthActionState>(
  AuthViewModel.new,
);
