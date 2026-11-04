import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/auth_session.dart';
import 'auth_service.dart';

/// SDK boundaries are injectable to verify ordering and errors without accounts.
abstract interface class FirebaseSessionBackend {
  Future<void> initialize();
  Stream<AuthUser?> get userChanges;
  Future<void> googlePopup();
  Future<void> googleCredential(String idToken);
  Future<void> signOut();
}

abstract interface class GoogleIdentityClient {
  Future<void> initialize();
  Future<String?> authenticate();
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseSessionBackend? backend,
    GoogleIdentityClient? google,
    bool? useWebPopup,
    this.beforeSignOut,
  }) : _backend = backend ?? FirebaseSdkBackend(),
       _google = google ?? GoogleSdkIdentityClient(),
       _web = useWebPopup ?? kIsWeb;

  final FirebaseSessionBackend _backend;
  final GoogleIdentityClient _google;
  final bool _web;
  final Future<void> Function()? beforeSignOut;
  Future<void>? _initialization, _googleInitialization;
  bool _ready = false, _working = false;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      await _backend.initialize();
      _ready = true;
    } catch (error) {
      _initialization = null;
      throw describeAuthFailure(error);
    }
  }

  @override
  Stream<AuthUser?> get userChanges => _backend.userChanges.handleError(
    (Object error, StackTrace stack) =>
        Error.throwWithStackTrace(describeAuthFailure(error), stack),
  );

  @override
  Future<void> signInWithGoogle() {
    if (!_ready) {
      return Future.error(
        const AuthFailure(
          AuthProblem.configuration,
          'Kết nối đăng nhập chưa sẵn sàng. Hãy thử kết nối lại.',
        ),
      );
    }
    // Web popup is invoked inside the original click, before any async setup.
    return _run(_web ? _backend.googlePopup : _nativeSignIn);
  }

  Future<void> _nativeSignIn() async {
    await (_googleInitialization ??= _initializeGoogle());
    final idToken = await _google.authenticate();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthFailure(
        AuthProblem.configuration,
        'Google chưa trả về thông tin đăng nhập hợp lệ. Hãy thử lại hoặc kiểm tra cấu hình Google Sign-In.',
      );
    }
    await _backend.googleCredential(idToken);
  }

  Future<void> _initializeGoogle() async {
    try {
      await _google.initialize();
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _run(() async {
    await beforeSignOut?.call();
    await _backend.signOut();
    if (!_web && _googleInitialization != null) await _google.signOut();
  });

  Future<void> _run(Future<void> Function() action) async {
    if (_working) {
      throw const AuthFailure(
        AuthProblem.unavailable,
        'Thao tác đăng nhập trước đang xử lý. Vui lòng chờ.',
      );
    }
    _working = true;
    try {
      await action();
    } catch (error) {
      throw describeAuthFailure(error);
    } finally {
      _working = false;
    }
  }
}

class FirebaseSdkBackend implements FirebaseSessionBackend {
  FirebaseAuth? _auth;
  FirebaseAuth get _requiredAuth =>
      _auth ?? (throw StateError('Auth not initialized'));

  @override
  Future<void> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    final existing = Firebase.apps
        .where((app) => app.name == '[DEFAULT]')
        .firstOrNull;
    final app = existing ?? await Firebase.initializeApp(options: options);
    if (app.options.projectId != options.projectId ||
        app.options.appId != options.appId) {
      throw const AuthFailure(
        AuthProblem.configuration,
        'Cấu hình đăng nhập không khớp ứng dụng TokenLedger.',
      );
    }
    _auth = FirebaseAuth.instanceFor(app: app);
  }

  @override
  Stream<AuthUser?> get userChanges => _requiredAuth.userChanges().map(
    (user) => user == null
        ? null
        : AuthUser(
            uid: user.uid,
            displayName: user.displayName,
            email: user.email,
            photoUrl: user.photoURL,
          ),
  );

  @override
  Future<void> googlePopup() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    await _requiredAuth.signInWithPopup(provider);
  }

  @override
  Future<void> googleCredential(String idToken) async {
    await _requiredAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Future<void> signOut() => _requiredAuth.signOut();
}

class GoogleSdkIdentityClient implements GoogleIdentityClient {
  @override
  Future<void> initialize() => GoogleSignIn.instance.initialize();
  @override
  Future<String?> authenticate() async =>
      (await GoogleSignIn.instance.authenticate()).authentication.idToken;
  @override
  Future<void> signOut() => GoogleSignIn.instance.signOut();
}

/// Never expose SDK messages: they can contain tokens, account data or URLs.
AuthFailure describeAuthFailure(Object error) {
  if (error is AuthFailure) return error;
  if (error is GoogleSignInException) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => const AuthFailure(
        AuthProblem.cancelled,
        'Bạn đã hủy đăng nhập Google. Có thể thử lại khi sẵn sàng.',
      ),
      GoogleSignInExceptionCode.interrupted => const AuthFailure(
        AuthProblem.unavailable,
        'Đăng nhập bị gián đoạn. Hãy thử lại.',
      ),
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError => const AuthFailure(
        AuthProblem.configuration,
        'Google Sign-In chưa được cấu hình đúng. Kiểm tra Google provider, package, SHA và cấu hình OAuth của ứng dụng.',
      ),
      GoogleSignInExceptionCode.uiUnavailable => const AuthFailure(
        AuthProblem.unavailable,
        'Chưa mở được màn hình Google. Kiểm tra Google Play services trên điện thoại rồi thử lại.',
      ),
      _ => const AuthFailure(
        AuthProblem.unknown,
        'Chưa đăng nhập được Google. Kiểm tra kết nối mạng và thử lại.',
      ),
    };
  }
  final code = switch (error) {
    FirebaseAuthException e => e.code,
    FirebaseException e => e.code,
    PlatformException e => e.code,
    _ => '',
  };
  return switch (code) {
    'popup-closed-by-user' ||
    'cancelled-popup-request' ||
    'sign_in_canceled' => const AuthFailure(
      AuthProblem.cancelled,
      'Bạn đã hủy đăng nhập Google. Có thể thử lại khi sẵn sàng.',
    ),
    'network-request-failed' || 'network_error' => const AuthFailure(
      AuthProblem.network,
      'Không kết nối được dịch vụ đăng nhập. Kiểm tra mạng và thử lại.',
    ),
    'popup-blocked' => const AuthFailure(
      AuthProblem.blockedPopup,
      'Trình duyệt đã chặn cửa sổ Google. Cho phép popup cho trang này rồi thử lại.',
    ),
    'unauthorized-domain' => const AuthFailure(
      AuthProblem.configuration,
      'Tên miền preview chưa được cho phép đăng nhập. Thêm localhost vào Authorized domains trong Firebase Authentication rồi thử lại.',
    ),
    'operation-not-allowed' ||
    'invalid-api-key' ||
    'app-not-authorized' ||
    'invalid-credential' ||
    'invalid-oauth-client-id' ||
    'configuration-not-found' ||
    'sign_in_failed' => const AuthFailure(
      AuthProblem.configuration,
      'Cấu hình Google Sign-In chưa hợp lệ. Kiểm tra provider, package, SHA và file Firebase rồi thử lại.',
    ),
    'user-disabled' => const AuthFailure(
      AuthProblem.unavailable,
      'Tài khoản này đã bị vô hiệu hóa. Hãy dùng tài khoản khác hoặc liên hệ người quản lý.',
    ),
    'too-many-requests' => const AuthFailure(
      AuthProblem.unavailable,
      'Có quá nhiều lần thử. Vui lòng chờ một lúc rồi đăng nhập lại.',
    ),
    _ =>
      error is UnsupportedError || error is MissingPluginException
          ? const AuthFailure(
              AuthProblem.configuration,
              'Nền tảng này chưa được cấu hình đăng nhập. Hãy dùng Android hoặc web preview.',
            )
          : const AuthFailure(
              AuthProblem.unknown,
              'Chưa kết nối được dịch vụ đăng nhập. Hãy thử lại.',
            ),
  };
}
