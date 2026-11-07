import 'package:shared_preferences/shared_preferences.dart';

/// Device-local token limits and the alert levels already delivered.
///
/// Kept on the device so the Firestore account schema and rules stay unchanged.
class TokenAlertStore {
  TokenAlertStore([Future<SharedPreferences> Function()? open])
    : _open = open ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _open;

  static const warnPercent = 80;
  static const maxLimit = 1000000000000;

  Future<Map<String, int>> loadLimits() async {
    final SharedPreferences prefs;
    try {
      prefs = await _open();
    } catch (_) {
      return {};
    }
    return {
      for (final key in prefs.getKeys())
        if (key.startsWith('token_limit.') && prefs.getInt(key) != null)
          key.substring('token_limit.'.length): prefs.getInt(key)!,
    };
  }

  Future<void> saveLimit(String accountId, int? limit) async {
    final prefs = await _open();
    if (limit == null) {
      await prefs.remove('token_limit.$accountId');
    } else {
      await prefs.setInt('token_limit.$accountId', limit);
    }
  }

  /// Returns 80 or 100 when that level is newly reached in [cycle], else null.
  /// The level is recorded before returning so it is delivered once per cycle.
  Future<int?> claimLevel({
    required String accountId,
    required String cycle,
    required int tokens,
    required int limit,
  }) async {
    if (limit <= 0) return null;
    final reached = tokens >= limit
        ? 100
        : tokens * 100 >= limit * warnPercent
        ? warnPercent
        : 0;
    if (reached == 0) return null;
    final prefs = await _open();
    final key = 'token_alert.$accountId.$cycle';
    if ((prefs.getInt(key) ?? 0) >= reached) return null;
    await prefs.setInt(key, reached);
    return reached;
  }

  /// True the first time [key] is claimed; later calls return false.
  Future<bool> claimOnce(String key) async {
    final prefs = await _open();
    if (prefs.getBool('token_alert.$key') ?? false) return false;
    await prefs.setBool('token_alert.$key', true);
    return true;
  }
}
