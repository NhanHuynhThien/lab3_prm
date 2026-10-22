import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_report.dart';
import '../services/crashlytics_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'export_report_dialog.dart';

class ProductCrashlyticsCard extends ConsumerWidget {
  const ProductCrashlyticsCard({super.key, this.status});

  final CrashlyticsStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'Kiểm thử Crashlytics',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              StatusTag(
                status?.enabled == true ? 'Đã kích hoạt' : 'Sẵn sàng',
                neutral: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            status?.lastRecordedError != null
                ? 'Lỗi gần nhất đã ghi (${status!.errorCount} lỗi): ${status!.lastRecordedError}'
                : 'Chưa có lỗi nào được ghi nhận trong phiên app này.',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(productFeaturesProvider.notifier)
                      .recordHandledError(
                        'Kiểm thử ngoại lệ non-fatal từ Profile diagnostic lúc ${DateTime.now().toIso8601String()}',
                      );
                  if (context.mounted) {
                    showMessage(
                      context,
                      'Đã gửi lỗi handled non-fatal tới Crashlytics (với user ID & custom keys).',
                    );
                  }
                },
                icon: const Icon(Icons.warning_amber_outlined, size: 18),
                label: const Text('Thử lỗi handled'),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận kích hoạt Crash'),
                      content: const Text(
                        'Thao tác này sẽ gọi FirebaseCrashlytics.instance.crash() làm ứng dụng kết thúc đột ngột để kiểm thử báo cáo trên Firebase Console.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref
                                .read(productFeaturesProvider.notifier)
                                .triggerCrash();
                          },
                          child: const Text('Kích hoạt Crash'),
                        ),
                      ],
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.flash_on_outlined, size: 18),
                label: const Text('Thử Fatal Crash'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductPdfStorageCard extends ConsumerWidget {
  const ProductPdfStorageCard({super.key, required this.reports});

  final List<ExportReport> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'Báo cáo PDF & Cloud Storage',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              const StatusTag('Sẵn sàng', neutral: false),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          const Text(
            'Kết xuất báo cáo chi phí AI thành định dạng PDF chất lượng cao và đồng bộ lên Firebase Cloud Storage.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton.icon(
            onPressed: () => ExportReportDialog.show(context),
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Xuất báo cáo PDF'),
          ),
          if (reports.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            const Divider(),
            const SizedBox(height: AppSpace.sm),
            const Text(
              'Báo cáo đã xuất gần đây:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...reports.take(3).map((rep) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rep.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${rep.periodLabel} · ${(rep.fileSizeBytes / 1024).toStringAsFixed(1)} KB · ${rep.status == 'uploaded_cloud' ? 'Cloud' : 'Local'}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rep.localPath != null)
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        tooltip: 'Mở PDF',
                        onPressed: () => ref
                            .read(reportManagementServiceProvider)
                            .openLocalReport(rep.id),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
