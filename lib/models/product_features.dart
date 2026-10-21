class AnalyticsStatus {
  const AnalyticsStatus({this.enabled = false, this.lastEvent, this.error});
  final bool enabled;
  final String? lastEvent, error;
}

class ProductConfig {
  const ProductConfig({
    this.recentLimit = 3,
    this.warningPercent = 80,
    this.recentSource = 'default',
    this.warningSource = 'default',
    this.fetchedAt,
    this.refreshing = false,
    this.error,
  });
  final int recentLimit, warningPercent;
  final String recentSource, warningSource;
  final DateTime? fetchedAt;
  final bool refreshing;
  final String? error;

  ProductConfig busy() => ProductConfig(
    recentLimit: recentLimit,
    warningPercent: warningPercent,
    recentSource: recentSource,
    warningSource: warningSource,
    fetchedAt: fetchedAt,
    refreshing: true,
  );

  ProductConfig failed() => ProductConfig(
    recentLimit: recentLimit,
    warningPercent: warningPercent,
    recentSource: recentSource,
    warningSource: warningSource,
    fetchedAt: fetchedAt,
    error:
        'Chưa lấy được cấu hình mới. Đang giữ giá trị khả dụng; hãy thử lại.',
  );
}
