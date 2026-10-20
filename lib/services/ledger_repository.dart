import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ledger.dart';

/// Firebase stays pending. A Firestore adapter can replace this interface later.
abstract interface class LedgerRepository {
  Future<LedgerData?> load();
  Future<void> save(LedgerData data);
}

class LocalLedgerRepository implements LedgerRepository {
  LocalLedgerRepository(this.preferences);
  final SharedPreferences preferences;
  static const storageKey = 'tokenledger.demo.v1';
  @override
  Future<LedgerData?> load() async {
    final raw = preferences.getString(storageKey);
    if (raw == null) return null;
    return LedgerData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(LedgerData data) async {
    final saved = await preferences.setString(
      storageKey,
      jsonEncode(data.toJson()),
    );
    if (!saved) throw StateError('Không thể lưu dữ liệu trên thiết bị.');
  }
}
