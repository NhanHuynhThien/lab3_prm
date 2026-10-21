import 'dart:async';

import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/services/auth_service.dart';
import 'package:token_ledger/services/firebase_auth_service.dart';

class FakeAuthService implements AuthService {
  AuthUser? user;
  Object? initializationError, signInError, signOutError;
  Completer<void>? initializationGate, signInGate, signOutGate;
  int initializations = 0, signIns = 0, signOuts = 0;
  final changes = StreamController<AuthUser?>.broadcast();

  void emit(AuthUser? value) {
    user = value;
    changes.add(value);
  }

  @override
  Future<void> initialize() async {
    initializations++;
    if (initializationGate != null) await initializationGate!.future;
    if (initializationError != null) throw initializationError!;
  }

  @override
  Stream<AuthUser?> get userChanges async* {
    yield user;
    yield* changes.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    signIns++;
    if (signInGate != null) await signInGate!.future;
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (signOutGate != null) await signOutGate!.future;
    if (signOutError != null) throw signOutError!;
    emit(null);
  }
}

class FakeFirebaseBackend implements FirebaseSessionBackend {
  int initializations = 0,
      popupCalls = 0,
      credentialCalls = 0,
      signOutCalls = 0;
  Object? initializationError, popupError, credentialError, signOutError;
  Completer<void>? initializationGate, popupGate;
  String? lastToken;
  final events = <String>[];
  @override
  Future<void> initialize() async {
    initializations++;
    if (initializationGate != null) await initializationGate!.future;
    if (initializationError != null) throw initializationError!;
  }

  @override
  Stream<AuthUser?> get userChanges => Stream.value(null);
  @override
  Future<void> googlePopup() async {
    popupCalls++;
    if (popupGate != null) await popupGate!.future;
    if (popupError != null) throw popupError!;
  }

  @override
  Future<void> googleCredential(String idToken) async {
    credentialCalls++;
    lastToken = idToken;
    if (credentialError != null) throw credentialError!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    events.add('firebase-sign-out');
    if (signOutError != null) throw signOutError!;
  }
}

class FakeGoogleIdentity implements GoogleIdentityClient {
  int initializations = 0, authentications = 0, signOutCalls = 0;
  String? token = 'test-id-token';
  Object? initializationError, authenticationError, signOutError;
  @override
  Future<void> initialize() async {
    initializations++;
    if (initializationError != null) throw initializationError!;
  }

  @override
  Future<String?> authenticate() async {
    authentications++;
    if (authenticationError != null) throw authenticationError!;
    return token;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) throw signOutError!;
  }
}
