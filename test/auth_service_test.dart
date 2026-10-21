import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/services/firebase_auth_service.dart';

import 'support/auth_fakes.dart';

Matcher problem(AuthProblem value) =>
    isA<AuthFailure>().having((e) => e.problem, 'problem', value);

void main() {
  test('bootstrap is shared, awaits initialization, and preserves signed-out stream', () async {
    final backend = FakeFirebaseBackend()
      ..initializationGate = Completer<void>();
    final service = FirebaseAuthService(
      backend: backend,
      google: FakeGoogleIdentity(),
      useWebPopup: true,
    );
    final first = service.initialize(), second = service.initialize();
    expect(identical(first, second), isTrue);
    expect(backend.initializations, 1);
    await expectLater(
      service.signInWithGoogle(),
      throwsA(problem(AuthProblem.configuration)),
    );
    backend.initializationGate!.complete();
    await Future.wait([first, second]);
    expect(await service.userChanges.first, isNull);
  });

  test('bootstrap failure can retry without exposing raw SDK error', () async {
    final backend = FakeFirebaseBackend()
      ..initializationError = StateError('raw-sensitive-details');
    final service = FirebaseAuthService(backend: backend, useWebPopup: true);
    await expectLater(
      service.initialize(),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message.contains('raw-sensitive-details'),
          'sanitized',
          isFalse,
        ),
      ),
    );
    backend.initializationError = null;
    await service.initialize();
    expect(backend.initializations, 2);
  });

  test('web calls Firebase popup in the click turn and does not initialize native Google', () async {
    final backend = FakeFirebaseBackend();
    final google = FakeGoogleIdentity();
    final service = FirebaseAuthService(
      backend: backend,
      google: google,
      useWebPopup: true,
    );
    await service.initialize();
    final operation = service.signInWithGoogle();
    expect(backend.popupCalls, 1);
    await operation;
    expect(google.initializations, 0);
    expect(backend.credentialCalls, 0);
  });

  test('native initializes Google once, exchanges ID token and signs Firebase out first', () async {
    final backend = FakeFirebaseBackend();
    final google = FakeGoogleIdentity();
    final service = FirebaseAuthService(
      backend: backend,
      google: google,
      useWebPopup: false,
    );
    await service.initialize();
    await service.signInWithGoogle();
    await service.signInWithGoogle();
    expect(google.initializations, 1);
    expect(google.authentications, 2);
    expect(backend.lastToken, 'test-id-token');
    expect(backend.credentialCalls, 2);
    expect(backend.popupCalls, 0);
    await service.signOut();
    expect(backend.events, ['firebase-sign-out']);
    expect(google.signOutCalls, 1);
  });

  test(
    'Google initialization failure retries instead of keeping failed future',
    () async {
      final backend = FakeFirebaseBackend();
      final google = FakeGoogleIdentity()
        ..initializationError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        );
      final service = FirebaseAuthService(
        backend: backend,
        google: google,
        useWebPopup: false,
      );
      await service.initialize();
      await expectLater(
        service.signInWithGoogle(),
        throwsA(problem(AuthProblem.configuration)),
      );
      google.initializationError = null;
      await service.signInWithGoogle();
      expect(google.initializations, 2);
      expect(backend.credentialCalls, 1);
    },
  );

  for (final token in <String?>[null, '']) {
    test('missing ID token ($token) never authenticates Firebase', () async {
      final backend = FakeFirebaseBackend();
      final google = FakeGoogleIdentity()..token = token;
      final service = FirebaseAuthService(
        backend: backend,
        google: google,
        useWebPopup: false,
      );
      await service.initialize();
      await expectLater(
        service.signInWithGoogle(),
        throwsA(problem(AuthProblem.configuration)),
      );
      expect(backend.credentialCalls, 0);
    });
  }

  test(
    'native cancellation is not a success and retry remains usable',
    () async {
      final backend = FakeFirebaseBackend();
      final google = FakeGoogleIdentity()
        ..authenticationError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        );
      final service = FirebaseAuthService(
        backend: backend,
        google: google,
        useWebPopup: false,
      );
      await service.initialize();
      await expectLater(
        service.signInWithGoogle(),
        throwsA(problem(AuthProblem.cancelled)),
      );
      expect(backend.credentialCalls, 0);
      google.authenticationError = null;
      await service.signInWithGoogle();
      expect(backend.credentialCalls, 1);
    },
  );

  test(
    'concurrent auth operations cannot report a dropped operation as success',
    () async {
      final backend = FakeFirebaseBackend()..popupGate = Completer<void>();
      final service = FirebaseAuthService(backend: backend, useWebPopup: true);
      await service.initialize();
      final first = service.signInWithGoogle();
      await expectLater(
        service.signOut(),
        throwsA(problem(AuthProblem.unavailable)),
      );
      expect(backend.signOutCalls, 0);
      backend.popupGate!.complete();
      await first;
      await service.signOut();
      expect(backend.signOutCalls, 1);
    },
  );

  test('Firebase signout failure never claims completion', () async {
    final backend = FakeFirebaseBackend()
      ..signOutError = FirebaseAuthException(code: 'network-request-failed');
    final google = FakeGoogleIdentity();
    final service = FirebaseAuthService(
      backend: backend,
      google: google,
      useWebPopup: false,
    );
    await service.initialize();
    await service.signInWithGoogle();
    await expectLater(service.signOut(), throwsA(problem(AuthProblem.network)));
    expect(google.signOutCalls, 0);
    backend.signOutError = null;
    await service.signOut();
    expect(google.signOutCalls, 1);
  });

  for (final item in <(String, AuthProblem)>[
    ('popup-closed-by-user', AuthProblem.cancelled),
    ('popup-blocked', AuthProblem.blockedPopup),
    ('network-request-failed', AuthProblem.network),
    ('unauthorized-domain', AuthProblem.configuration),
    ('operation-not-allowed', AuthProblem.configuration),
    ('user-disabled', AuthProblem.unavailable),
    ('too-many-requests', AuthProblem.unavailable),
    ('unrecognized', AuthProblem.unknown),
  ]) {
    test('Firebase ${item.$1} maps to actionable sanitized feedback', () {
      final error = describeAuthFailure(
        FirebaseAuthException(
          code: item.$1,
          message: 'private-token-and-email',
        ),
      );
      expect(error.problem, item.$2);
      expect(error.message.contains('private-token-and-email'), isFalse);
    });
  }
  test('unsupported platform and Play services errors are sanitized', () {
    expect(
      describeAuthFailure(UnsupportedError('raw')).problem,
      AuthProblem.configuration,
    );
    expect(
      describeAuthFailure(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.uiUnavailable,
        ),
      ).message,
      contains('Google Play services'),
    );
    expect(
      describeAuthFailure(PlatformException(code: 'network_error')).problem,
      AuthProblem.network,
    );
  });
}
