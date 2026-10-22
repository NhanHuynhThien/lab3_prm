import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';

/// Explicit local-build opt-in for the owner who authorized this Mac's data.
/// A token alone never enables automatic access for other Google accounts.
class ProviderAutoConnect {
  const ProviderAutoConnect({this.ownerEmail = '', this.token = ''});
  final String ownerEmail, token;

  bool permits(AuthUser? user) =>
      user != null &&
      user.uid.isNotEmpty &&
      ownerEmail.trim().isNotEmpty &&
      user.email?.trim().toLowerCase() == ownerEmail.trim().toLowerCase() &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(token);
}

final providerAutoConnectProvider = Provider<ProviderAutoConnect>(
  (ref) => const ProviderAutoConnect(
    ownerEmail: String.fromEnvironment('PROVIDER_BRIDGE_OWNER_EMAIL'),
    token: String.fromEnvironment('PROVIDER_BRIDGE_TOKEN'),
  ),
);
