import 'package:flutter/material.dart';

import '../models/export_report.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';

class ExportReportPeriodSelector extends StatelessWidget {
  const ExportReportPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.isWorking,
    required this.onSelected,
  });

  final String selectedPeriod;
  final bool isWorking;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kỳ báo cáo:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: 8,
          children: ['Tháng này', '30 ngày qua', 'Toàn bộ dữ liệu'].map((p) {
            final isSelected = selectedPeriod == p;
            return ChoiceChip(
              label: Text(p),
              selected: isSelected,
              onSelected: isWorking
                  ? null
                  : (val) {
                      if (val) onSelected(p);
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ExportReportPreviewCard extends StatelessWidget {
  const ExportReportPreviewCard({
    super.key,
    required this.sessionCount,
    required this.totalCostMicros,
    required this.accountCount,
    required this.totalTokens,
  });

  final int sessionCount;
  final int totalCostMicros;
  final int accountCount;
  final int totalTokens;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dữ liệu sẽ được kết xuất:',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$sessionCount phiên công việc',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                money(totalCostMicros),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$accountCount tài khoản · ${compactTokens(totalTokens)} token đã ghi nhận',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class ExportCompletedCard extends StatelessWidget {
  const ExportCompletedCard({super.key, required this.report});

  final ExportReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.status == 'uploaded_cloud'
                      ? 'Đã tạo và tải lên Cloud Storage thành công!'
                      : 'Đã tạo file PDF thành công!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'File: ${report.fileName} (${(report.fileSizeBytes / 1024).toStringAsFixed(1)} KB)',
            style: const TextStyle(fontSize: 12),
          ),
          if (report.storageUrl != null) ...[
            const SizedBox(height: 6),
            Text(
              'Cloud URL: ${report.storageUrl!}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
