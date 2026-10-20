import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ledger.dart';
import 'ledger_validation.dart';

enum LedgerStorageProblem { read, corrupt, unsupportedVersion, write }

class LedgerStorageException implements Exception {
  const LedgerStorageException(this.problem, this.message);
  final LedgerStorageProblem problem;
  final String message;
  @override
  String toString() => message;
}

abstract interface class RecoverableLedgerRepository {
  Future<void> replaceUnreadable(LedgerData data);
}

/// Firebase stays pending. A Firestore adapter can replace this interface later.
abstract interface class LedgerRepository {
  Future<LedgerData?> load();
  Future<void> save(LedgerData data);
}

class LocalLedgerRepository
    implements LedgerRepository, RecoverableLedgerRepository {
  LocalLedgerRepository(SharedPreferences preferences)
    : _open = (() async => preferences);
  LocalLedgerRepository.open({
    Future<SharedPreferences> Function()? openPreferences,
  }) : _open = openPreferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _open;
  static const storageKey = 'tokenledger.demo.v1';
  static const backupKey = '$storageKey.recovery-backup';
  static const migrationBackupKey = '$storageKey.migration-v1-backup';
  Future<LedgerData?>? _loadOperation;
  @override
  Future<LedgerData?> load() =>
      _loadOperation ??= _load().whenComplete(() => _loadOperation = null);

  Future<LedgerData?> _load() async {
    Object? raw;
    try {
      final preferences = await _open();
      // Refresh the plugin cache so explicit Retry can see repaired storage.
      await preferences.reload();
      raw = preferences.get(storageKey);
    } catch (_) {
      throw const LedgerStorageException(
        LedgerStorageProblem.read,
        'Không đọc được dữ liệu trên thiết bị. Hãy thử lại.',
      );
    }
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['schemaVersion'] is int &&
          ![1, 2].contains(json['schemaVersion'])) {
        throw const LedgerStorageException(
          LedgerStorageProblem.unsupportedVersion,
          'Phiên bản dữ liệu chưa được hỗ trợ. Dữ liệu gốc vẫn được giữ nguyên.',
        );
      }
      final data = LedgerData.fromJson(json);
      LedgerValidation.snapshot(data);
      if (json['schemaVersion'] == 1) {
        // Validate first; backup must succeed before replacing the only old blob.
        try {
          final preferences = await _open();
          if (!await preferences.setString(
            migrationBackupKey,
            jsonEncode({'value': raw}),
          )) {
            throw StateError('migration backup failed');
          }
        } catch (_) {
          throw const LedgerStorageException(
            LedgerStorageProblem.write,
            'Không sao lưu được dữ liệu phiên bản cũ. Chưa chuyển đổi dữ liệu.',
          );
        }
        await _write(data);
      }
      return data;
    } on LedgerStorageException {
      rethrow;
    } catch (_) {
      throw const LedgerStorageException(
        LedgerStorageProblem.corrupt,
        'Dữ liệu local không hợp lệ. Dữ liệu gốc vẫn được giữ nguyên.',
      );
    }
  }

  @override
  Future<void> save(LedgerData data) async {
    if (_loadOperation != null) await _loadOperation;
    await _write(data);
  }

  Future<void> _write(LedgerData data) async {
    LedgerValidation.snapshot(data);
    try {
      final preferences = await _open();
      final saved = await preferences.setString(
        storageKey,
        jsonEncode(data.toJson()),
      );
      if (!saved) throw StateError('write failed');
    } catch (_) {
      throw const LedgerStorageException(
        LedgerStorageProblem.write,
        'Không thể lưu dữ liệu trên thiết bị. Thay đổi chưa được xác nhận.',
      );
    }
  }

  @override
  Future<void> replaceUnreadable(LedgerData data) async {
    LedgerValidation.snapshot(data);
    try {
      final preferences = await _open();
      await preferences.reload();
      final raw = preferences.get(storageKey);
      if (raw != null) {
        final saved = await preferences.setString(
          backupKey,
          jsonEncode({'value': raw}),
        );
        if (!saved) throw StateError('backup failed');
      }
    } catch (_) {
      throw const LedgerStorageException(
        LedgerStorageProblem.write,
        'Không tạo được bản sao dữ liệu cũ. Chưa thay thế dữ liệu.',
      );
    }
    await save(data);
  }
}
