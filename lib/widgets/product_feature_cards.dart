import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_report.dart';
import '../theme/app_theme.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'export_report_dialog.dart';

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
                  'Báo cáo của bạn',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          const Text(
            'Xuất sổ ghi nhận theo kỳ ra PDF. Lưu và mở file trên thiết bị, không tải dữ liệu lên cloud.',
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
                            '${rep.periodLabel} · ${(rep.fileSizeBytes / 1024).toStringAsFixed(1)} KB · Trên thiết bị',
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
