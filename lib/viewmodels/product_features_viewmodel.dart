import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_features.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import 'auth_viewmodel.dart';
import 'ledger_viewmodel.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final service = AnalyticsService(null);
  ref.onDispose(() => unawaited(service.close()));
  return service;
});
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  final service = RemoteConfigService(null);
  ref.onDispose(() => unawaited(service.close()));
  return service;
});
final analyticsStatusProvider = StreamProvider<AnalyticsStatus>(
  (ref) => ref.watch(analyticsServiceProvider).changes,
);
final productConfigStreamProvider = StreamProvider<ProductConfig>(
  (ref) => ref.watch(remoteConfigServiceProvider).changes,
);
final productConfigProvider = Provider<ProductConfig>(
  (ref) =>
      ref.watch(productConfigStreamProvider).asData?.value ??
      ref.watch(remoteConfigServiceProvider).current,
);

/// Only the root auth gate owns this lifecycle. Initial demo never reads Auth.
final featureSessionProvider = Provider<void>((ref) {
  final demo = ref.watch(demoSessionProvider);
  final uid = demo
      ? null
      : ref.watch(authSessionProvider.select((s) => s.asData?.value?.uid));
  final analytics = ref.watch(analyticsServiceProvider);
  final config = ref.watch(remoteConfigServiceProvider);
  var disposed = false;
  ref.onDispose(() => disposed = true);
  scheduleMicrotask(() {
    if (disposed) return;
    unawaited(analytics.setOwner(uid));
    if (uid != null) unawaited(config.refresh());
  });
});

class ProductFeaturesViewModel extends Notifier<void> {
  @override
  void build() {}
  void screen(String name) => unawaited(
    ref.read(analyticsServiceProvider).record(ProductEvent.screen(name)),
  );
  void detail(String type) => unawaited(
    ref.read(analyticsServiceProvider).record(ProductEvent.detail(type)),
  );
  Future<bool> refreshConfig() async {
    await ref.read(remoteConfigServiceProvider).refresh();
    if (!ref.mounted) return false;
    final success = ref.read(remoteConfigServiceProvider).current.error == null;
    await ref
        .read(analyticsServiceProvider)
        .record(ProductEvent.refresh(success));
    return success;
  }
}

final productFeaturesProvider =
    NotifierProvider<ProductFeaturesViewModel, void>(
      ProductFeaturesViewModel.new,
    );
