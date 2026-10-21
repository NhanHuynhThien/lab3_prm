/// Public identity only. Provider credentials never enter ledger models/storage.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String? displayName, email, photoUrl;
}

enum AuthProblem {
  cancelled,
  network,
  configuration,
  blockedPopup,
  unavailable,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.problem, this.message);
  final AuthProblem problem;
  final String message;
  bool get isCancellation => problem == AuthProblem.cancelled;
  @override
  String toString() => message;
}
