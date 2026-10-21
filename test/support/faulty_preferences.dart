import 'package:shared_preferences/shared_preferences.dart';

class FaultyPreferences implements SharedPreferences {
  final Map<String, Object> values = {};
  bool failReads = false;
  String? failKey;
  bool throwWrites = false;

  @override
  Object? get(String key) {
    if (failReads) throw StateError('read failure');
    return values[key];
  }

  @override
  Future<void> reload() async {
    if (failReads) throw StateError('read failure');
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (throwWrites) throw StateError('write failure');
    if (key == failKey) return false;
    values[key] = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
