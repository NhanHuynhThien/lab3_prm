import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider_usage.dart';

abstract interface class ProviderSyncService {
  Future<ProviderSnapshot> fetch(String pairingToken);
  void close();
}

class LoopbackProviderSync implements ProviderSyncService {
  LoopbackProviderSync({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static final endpoint = Uri.parse('http://127.0.0.1:8787/v1/snapshot');

  @override
  Future<ProviderSnapshot> fetch(String pairingToken) async {
    try {
      return await _fetch(pairingToken).timeout(const Duration(seconds: 30));
    } catch (error) {
      if (error is ProviderSyncFailure) rethrow;
      throw const ProviderSyncFailure(
        'Chưa kết nối được nguồn trên máy. Kiểm tra companion và thử lại.',
      );
    }
  }

  Future<ProviderSnapshot> _fetch(String pairingToken) async {
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
