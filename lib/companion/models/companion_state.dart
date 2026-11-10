/// Signed-in desktop account. Only the Firebase UID and email are kept;
/// the refresh token lives in the macOS Keychain.
class CompanionAccount {
  const CompanionAccount({required this.uid, this.email});
  final String uid;
  final String? email;

  static CompanionAccount? fromJson(Object? value) {
    if (value is! Map) return null;
    final uid = value['uid'];
    if (uid is! String || uid.isEmpty || uid.length > 128) return null;
    final email = value['email'];
    return CompanionAccount(
      uid: uid,
      email: email is String
          ? email.substring(0, email.length.clamp(0, 254))
          : null,
    );
  }

  Map<String, Object?> toJson() => {'uid': uid, 'email': email};
}

/// Provider IDs a desktop snapshot can report as ready.
const companionSources = ['codex', 'claude', 'google', 'antigravity'];

class CompanionState {
  const CompanionState({
    this.account,
    this.enabled = false,
    this.consent = false,
    this.busy = false,
    this.signingIn = false,
    this.lastSyncedAt,
    this.providers = const [],
    this.error,
    this.autoStart = false,
    this.packaged = false,
  });

  final CompanionAccount? account;
  final bool enabled;
  final bool consent;
  final bool busy;
  final bool signingIn;
  final String? lastSyncedAt;
  final List<String> providers;
  final String? error;
  final bool autoStart;
  final bool packaged;

  bool get active => enabled && consent;

  static const _keep = Object();

  CompanionState copyWith({
    Object? account = _keep,
    bool? enabled,
    bool? consent,
    bool? busy,
    bool? signingIn,
    Object? lastSyncedAt = _keep,
    List<String>? providers,
    Object? error = _keep,
    bool? autoStart,
    bool? packaged,
  }) => CompanionState(
    account: identical(account, _keep)
        ? this.account
        : account as CompanionAccount?,
    enabled: enabled ?? this.enabled,
    consent: consent ?? this.consent,
    busy: busy ?? this.busy,
    signingIn: signingIn ?? this.signingIn,
    lastSyncedAt: identical(lastSyncedAt, _keep)
        ? this.lastSyncedAt
        : lastSyncedAt as String?,
    providers: providers ?? this.providers,
    error: identical(error, _keep) ? this.error : error as String?,
    autoStart: autoStart ?? this.autoStart,
    packaged: packaged ?? this.packaged,
  );
}

/// Persisted per-machine choices, keyed by the UID that granted consent.
class CompanionPreferences {
  const CompanionPreferences({
    this.uid,
    this.enabled = false,
    this.consent = false,
    this.lastSyncedAt,
    this.providers = const [],
  });
  final String? uid;
  final bool enabled;
  final bool consent;
  final String? lastSyncedAt;
  final List<String> providers;

  static CompanionPreferences fromJson(Object? value) {
    if (value is! Map) return const CompanionPreferences();
    final synced = value['lastSyncedAt'];
    final providers = value['providers'];
    return CompanionPreferences(
      uid: value['uid'] is String ? value['uid'] as String : null,
      enabled: value['enabled'] == true,
      consent: value['consent'] == true,
      lastSyncedAt: synced is String && DateTime.tryParse(synced) != null
          ? synced
          : null,
      providers: providers is List
          ? providers
                .whereType<String>()
                .where(companionSources.contains)
                .toList()
          : const [],
    );
  }

  Map<String, Object?> toJson() => {
    'uid': uid,
    'enabled': enabled,
    'consent': consent,
    'lastSyncedAt': lastSyncedAt,
    'providers': providers,
  };
}
