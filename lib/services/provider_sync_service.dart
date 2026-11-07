import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/provider_usage.dart';

abstract interface class ProviderSyncService {
  Future<ProviderSnapshot> fetch(String pairingToken);
  void close();
}

class LoopbackProviderSync implements ProviderSyncService {
  LoopbackProviderSync({http.Client? client, List<Uri>? endpoints})
    : _client = client ?? http.Client(),
      endpoints = endpoints ?? defaultEndpoints;
  final http.Client _client;
  final List<Uri> endpoints;

  /// 127.0.0.1 works with `adb reverse` or on the host itself; the Android
  /// emulator also reaches the Mac's loopback as 10.0.2.2 without it.
  static List<Uri> get defaultEndpoints => [
    Uri.parse('http://127.0.0.1:8787/v1/snapshot'),
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      Uri.parse('http://10.0.2.2:8787/v1/snapshot'),
  ];

  @override
  Future<ProviderSnapshot> fetch(String pairingToken) async {
    for (final endpoint in endpoints) {
      try {
        return await _fetch(
          endpoint,
          pairingToken,
        ).timeout(const Duration(seconds: 30));
      } on ProviderSyncFailure {
        rethrow;
      } catch (_) {
        // Unreachable endpoint: try the next one before reporting.
      }
    }
    throw const ProviderSyncFailure(
      'Chưa kết nối được nguồn trên máy. Kiểm tra companion và thử lại.',
    );
  }

  Future<ProviderSnapshot> _fetch(Uri endpoint, String pairingToken) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(pairingToken)) {
      throw const ProviderSyncFailure('Mã ghép nối cần đủ 64 ký tự hex.');
    }
    final request = http.Request('GET', endpoint)
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer $pairingToken';
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw ProviderSyncFailure(
        response.statusCode == 401
            ? 'Mã ghép nối không đúng. Kiểm tra mã của companion.'
            : 'Nguồn đồng bộ chưa sẵn sàng. Hãy thử lại.',
      );
    }
    var count = 0;
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      count += chunk.length;
      if (count > 512 * 1024) {
        throw const ProviderSyncFailure('Snapshot vượt giới hạn hỗ trợ.');
      }
      bytes.addAll(chunk);
    }
    return ProviderSnapshot.fromJson(
      Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
    );
  }

  @override
  void close() => _client.close();
}

class ProviderSyncFailure implements Exception {
  const ProviderSyncFailure(this.message);
  final String message;
}
