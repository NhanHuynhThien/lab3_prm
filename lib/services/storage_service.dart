import 'dart:async';

import 'package:flutter/foundation.dart';

abstract interface class StorageTransport {
  Future<String> uploadReport({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  });

  Future<void> deleteReport({required String uid, required String fileName});
}

class StorageService {
  StorageService(this._transport);

  final StorageTransport? _transport;

  bool get isAvailable => _transport != null;

  Future<String> uploadReport({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    if (_transport == null) {
      throw StateError(
        'Firebase Cloud Storage chưa sẵn sàng trên nền tảng này.',
      );
    }
    return _transport.uploadReport(
      uid: uid,
      fileName: fileName,
      bytes: bytes,
      onProgress: onProgress,
    );
  }

  Future<void> deleteReport({
    required String uid,
    required String fileName,
  }) async {
    if (_transport == null) return;
    return _transport.deleteReport(uid: uid, fileName: fileName);
  }
}
