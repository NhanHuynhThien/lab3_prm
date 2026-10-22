import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_usage.dart';
import '../models/cloud_sync_status.dart';
import '../services/provider_sync_service.dart';

final providerSyncServiceFactoryProvider =
    Provider<ProviderSyncService Function()>((ref) => LoopbackProviderSync.new);

final providerSyncServiceProvider = Provider<ProviderSyncService>((ref) {
  final service = ref.read(providerSyncServiceFactoryProvider)();
  ref.onDispose(service.close);
  return service;
});

class ProviderSyncState {
  const ProviderSyncState({
    this.enabled = false,
    this.working = false,
    this.snapshot,
    this.error,
  });
  final bool enabled, working;
  final ProviderSnapshot? snapshot;
  final String? error;
}

/// Owned by the session's isolated ProviderContainer; never persisted/clouded.
class ProviderSyncViewModel extends Notifier<ProviderSyncState> {
  String? _token;
  Timer? _timer;
  int _epoch = 0;
  bool _foreground = true;

  @override
  ProviderSyncState build() {
    final lifecycle = AppLifecycleListener(
      onStateChange: (value) {
        _foreground = value == AppLifecycleState.resumed;
        if (_foreground && state.enabled) unawaited(refresh());
      },
    );
    ref.onDispose(() {
      _epoch++;
      _token = null;
      _timer?.cancel();
      lifecycle.dispose();
    });
    return const ProviderSyncState();
  }

  Future<void> connect(String token) async {
    if (state.working) return;
    if (ref.read(cloudOwnerProvider) == null) {
      state = const ProviderSyncState(
        error: 'Đăng nhập Google trước khi ghép nguồn.',
      );
      return;
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(token)) {
      state = ProviderSyncState(
        enabled: state.enabled,
        snapshot: state.snapshot,
        error: 'Mã ghép nối cần đủ 64 ký tự hex.',
      );
      return;
    }
    _epoch++;
    _token = token;
    _timer?.cancel();
    state = const ProviderSyncState(enabled: true);
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_foreground) unawaited(refresh());
    });
    await refresh();
  }

  Future<void> refresh() async {
    final token = _token;
    if (token == null || state.working) return;
    final epoch = _epoch;
    final last = state.snapshot;
    state = ProviderSyncState(enabled: true, working: true, snapshot: last);
    try {
      final next = await ref.read(providerSyncServiceProvider).fetch(token);
      if (!ref.mounted || epoch != _epoch) return;
      final now = DateTime.now().toUtc();
      if (next.collectedAt.isAfter(now.add(const Duration(minutes: 5))) ||
          next.providers.any(
            (p) =>
                p.observedAt?.isAfter(now.add(const Duration(minutes: 5))) ??
                false,
          )) {
        throw const ProviderSyncFailure(
          'Đồng hồ nguồn chưa khớp. Kiểm tra lại máy.',
        );
      }
      final rows = next.providers.map((row) {
        final old = last?.providers.where((p) => p.id == row.id).firstOrNull;
        return row.status == 'error' && old?.status == 'ready'
            ? old!.disconnected()
            : row.status == 'error' && old?.status == 'error'
            ? old!
            : row;
      }).toList();
      state = ProviderSyncState(
        enabled: true,
        snapshot: ProviderSnapshot(next.collectedAt, List.unmodifiable(rows)),
      );
      assert(() {
        debugPrint(
          'Provider sync: ${rows.where((r) => r.status == 'ready').length} ready sources; '
          '${rows.fold<int>(0, (n, r) => n + r.models.length)} model rows.',
        );
        return true;
      }());
    } catch (error) {
      if (!ref.mounted || epoch != _epoch) return;
      state = ProviderSyncState(
        enabled: true,
        snapshot: last,
        error: error is ProviderSyncFailure
            ? error.message
            : 'Dữ liệu đồng bộ chưa hợp lệ. Hãy thử lại.',
      );
    }
  }

  void disconnect() {
    _epoch++;
    _timer?.cancel();
    _token = null;
    state = const ProviderSyncState();
  }
}

final providerSyncProvider =
    NotifierProvider<ProviderSyncViewModel, ProviderSyncState>(
      ProviderSyncViewModel.new,
    );
