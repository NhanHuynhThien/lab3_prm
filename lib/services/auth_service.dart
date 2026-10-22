import '../models/auth_session.dart';

abstract interface class AuthService {
  Future<void> initialize();
  Stream<AuthUser?> get userChanges;
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

/// Bootstrap supplies the real adapter; isolated UI tests need no Firebase SDK.
class UnavailableAuthService implements AuthService {
  const UnavailableAuthService();
  static const failure = AuthFailure(
    AuthProblem.configuration,
    'Chưa có kết nối đăng nhập. Hãy kiểm tra cấu hình Firebase.',
  );
  @override
  Future<void> initialize() => Future.error(failure);
  @override
  Stream<AuthUser?> get userChanges => Stream.error(failure);
  @override
  Future<void> signInWithGoogle() => Future.error(failure);
  @override
  Future<void> signOut() => Future.error(failure);
}
