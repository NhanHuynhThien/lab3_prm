import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'settings_group.dart';

/// Recently exported PDFs kept on this device. Exporting lives in Analytics.
class ExportedReports extends ConsumerWidget {
  const ExportedReports({super.key});

  /// Rows shown here; older reports stay on the device.
  static const visibleCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports =
        ref.watch(reportsListProvider).asData?.value ??
        ref.watch(reportManagementServiceProvider).reports;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsTile(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Báo cáo đã xuất',
          subtitle: reports.isEmpty
              ? 'Chưa có báo cáo. Xuất PDF ở tab Phân tích.'
              : 'Lưu trên thiết bị, không tải lên cloud.',
        ),
        for (final rep in reports.take(visibleCount))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.muted),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rep.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge,
                      ),
                      Text(
                        '${rep.periodLabel} · ${(rep.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (rep.localPath != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Mở PDF',
                    onPressed: () async {
                      try {
                        await ref
                            .read(reportManagementServiceProvider)
                            .openLocalReport(rep.id);
                      } catch (e) {
                        if (context.mounted) showMessage(context, errorText(e));
                      }
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
