import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_report.dart';
import '../models/notification_item.dart';
import '../models/product_features.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';
import '../services/pdf_report_service.dart';
import '../services/remote_config_service.dart';
import '../services/report_management_service.dart';
import '../services/storage_service.dart';
import '../services/platform_api_service.dart';
import 'auth_viewmodel.dart';

final platformApiProvider = Provider<PlatformApiService?>((ref) => null);

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

final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  final service = CrashlyticsService(null);
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(null);
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final pdfReportServiceProvider = Provider<PdfReportService>((ref) {
  return const PdfReportService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(null);
});

final reportManagementServiceProvider = Provider<ReportManagementService>((
  ref,
) {
  final service = ReportManagementService(
    pdfService: ref.watch(pdfReportServiceProvider),
    storageService: ref.watch(storageServiceProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final analyticsStatusProvider = StreamProvider<AnalyticsStatus>(
  (ref) => ref.watch(analyticsServiceProvider).changes,
);

final crashlyticsStatusProvider = StreamProvider<CrashlyticsStatus>(
  (ref) => ref.watch(crashlyticsServiceProvider).changes,
);

final notificationListProvider = StreamProvider<List<NotificationItem>>(
  (ref) => ref.watch(notificationServiceProvider).notificationsStream,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationListProvider).asData?.value;
  if (items != null) {
    return items.where((i) => !i.isRead).length;
  }
  return ref.watch(notificationServiceProvider).unreadCount;
});

final reportsListProvider = StreamProvider<List<ExportReport>>(
  (ref) => ref.watch(reportManagementServiceProvider).reportsStream,
);

final productConfigStreamProvider = StreamProvider<ProductConfig>(
  (ref) => ref.watch(remoteConfigServiceProvider).changes,
);

final productConfigProvider = Provider<ProductConfig>(
  (ref) =>
      ref.watch(productConfigStreamProvider).asData?.value ??
      ref.watch(remoteConfigServiceProvider).current,
);

/// The root auth gate owns SDK lifecycle for the authenticated owner.
final featureSessionProvider = Provider<void>((ref) {
  final uid = ref.watch(
    authSessionProvider.select((s) => s.asData?.value?.uid),
  );
  final analytics = ref.watch(analyticsServiceProvider);
  final config = ref.watch(remoteConfigServiceProvider);
  final crashlytics = ref.watch(crashlyticsServiceProvider);
  final notifications = ref.watch(notificationServiceProvider);
  final reportManager = ref.watch(reportManagementServiceProvider);

  var disposed = false;
  ref.onDispose(() => disposed = true);
  scheduleMicrotask(() {
    if (disposed) return;
    unawaited(analytics.setOwner(uid));
    unawaited(crashlytics.bindOwner(uid));
    unawaited(notifications.bindOwner(uid));
    reportManager.bindOwner(uid);
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

  Future<bool> requestNotifications() =>
      ref.read(notificationServiceProvider).requestPermission();

  Future<void> recordHandledError(String message) async {
    await ref
        .read(crashlyticsServiceProvider)
        .recordHandled(
          Exception(message),
          StackTrace.current,
          'user_diagnostic_test',
        );
  }

  void triggerCrash() {
    ref.read(crashlyticsServiceProvider).triggerTestCrash();
  }
}

final productFeaturesProvider =
    NotifierProvider<ProductFeaturesViewModel, void>(
      ProductFeaturesViewModel.new,
    );
