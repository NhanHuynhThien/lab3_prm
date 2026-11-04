import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_item.dart';
import 'platform_api_service.dart';
import 'notification_contracts.dart';
export 'notification_contracts.dart' show NotificationStore;

class PlatformNotificationStore implements NotificationStore {
  PlatformNotificationStore(this.api);
  final PlatformApiService api;
  Future<String>? _device;
  Future<String> _installationId() => _device ??= () async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString('tokenledger_installation_id');
    if (old != null && RegExp(r'^[a-f0-9]{32}$').hasMatch(old)) return old;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await prefs.setString('tokenledger_installation_id', id);
    return id;
  }();
  @override
  Future<void> register(String uid, String token) async {
    await api.request(
      uid,
      '/v1/me/devices/${await _installationId()}',
      method: 'PUT',
      body: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        'appVersion': '0.1.0+1',
        'consent': true,
      },
    );
  }

  @override
  Future<void> unregister(String uid) async {
    await api.request(
      uid,
      '/v1/me/devices/${await _installationId()}',
      method: 'DELETE',
    );
  }

  @override
  Future<List<NotificationItem>> inbox(String uid) async {
    final data = await api.request(uid, '/v1/me/notifications');
    return (data['notifications'] as List).map((raw) {
      final n = raw as Map<String, dynamic>;
      return NotificationItem(
        id: n['id'] as String,
        title: n['title'] as String,
        body: n['body'] as String,
        receivedAt: DateTime.parse(n['createdAt'] as String).toLocal(),
        isRead: n['readAt'] != null,
        route: '/${n['target']}',
        data: {'ownerUid': uid},
      );
    }).toList();
  }

  @override
  Future<void> read(String uid, String id) async {
    await api.request(
      uid,
      '/v1/me/notifications/$id/read',
      method: 'POST',
      body: {},
    );
  }
}
