import 'dart:convert';

import 'package:http/http.dart' as http;

class PlatformFailure implements Exception {
  const PlatformFailure(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Firebase tokens are obtained at request time, never stored or logged.
class PlatformApiService {
  PlatformApiService({
    required this.owner,
    required this.tokenFor,
    String baseUrl = const String.fromEnvironment(
      'TOKENLEDGER_API_URL',
      defaultValue: 'http://127.0.0.1:8788',
    ),
    http.Client? client,
  }) : base = Uri.parse(baseUrl),
       _client = client ?? http.Client() {
    final loopback = {'localhost', '127.0.0.1', '10.0.2.2'}.contains(base.host);
    if (base.scheme != 'https' && !(base.scheme == 'http' && loopback)) {
      throw ArgumentError('API requires HTTPS or a development loopback host.');
    }
    if (base.userInfo.isNotEmpty || base.hasQuery || base.hasFragment) {
      throw ArgumentError('Invalid API base URL.');
    }
  }
  final Uri base;
  final String? Function() owner;
  final Future<String?> Function(String uid) tokenFor;
  final http.Client _client;
  bool _closed = false;

  void _check(String uid) {
    if (_closed || owner() != uid) {
      throw const PlatformFailure('Phiên đăng nhập đã thay đổi.');
    }
  }

  Future<Map<String, dynamic>> request(
    String uid,
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    _check(uid);
    if (!path.startsWith('/v1/')) throw ArgumentError('Invalid API path');
    try {
      final token = await tokenFor(uid);
      _check(uid);
      if (token == null) {
        throw const PlatformFailure('Hãy đăng nhập lại Google.');
      }
      final response = await _client
          .send(
            http.Request(method, base.resolve(path))
              ..headers.addAll({
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              })
              ..body = body == null ? '' : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
      final text = await response.stream.bytesToString().timeout(
        const Duration(seconds: 15),
      );
      _check(uid);
      if (text.length > 256000) {
        throw const PlatformFailure('Kết quả vượt giới hạn.');
      }
      final data = jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data['error'];
        throw PlatformFailure(
          message is String && message.length < 300
              ? message
              : 'Backend chưa hoàn tất yêu cầu.',
          response.statusCode,
        );
      }
      return data;
    } on PlatformFailure {
      rethrow;
    } catch (_) {
      _check(uid);
      throw const PlatformFailure(
        'Chưa kết nối được backend. Kiểm tra mạng và thử lại.',
      );
    }
  }

  void close() {
    _closed = true;
    _client.close();
  }
}
