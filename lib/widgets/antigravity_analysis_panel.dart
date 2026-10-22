import 'package:flutter/material.dart';

import '../models/antigravity_analysis.dart';
import '../models/provider_usage.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';

class AntigravityAnalysisPanel extends StatelessWidget {
  const AntigravityAnalysisPanel({
    super.key,
    required this.source,
    required this.now,
  });
  final ProviderUsage source;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final groups = antigravityGroups(source, now);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(group.title),
                Text(group.assessment, style: text.bodyLarge),
                const SizedBox(height: AppSpace.xl),
                for (final window in group.windows) ...[
                  _QuotaWindow(source: source, window: window, now: now),
                  const SizedBox(height: AppSpace.lg),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        Panel(
          color: AppColors.soft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Đọc báo cáo Antigravity'),
              Text(
                '${groups.length} nhóm · ${source.windows.length} cửa sổ quota từ lệnh /usage chính thức.',
              ),
              const SizedBox(height: AppSpace.md),
              const Text(
                'Quota cho biết phần hạn mức còn lại. Nó không phải số token, số lượt hỏi, thời gian làm việc hoặc hóa đơn.',
              ),
              const SizedBox(height: AppSpace.md),
              const Text(
                'Chưa có lịch sử token IDE để vẽ xu hướng hoặc dự báo tốc độ dùng. Nhóm quota không cho biết bạn đã sử dụng từng model nào.',
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                source.observedAt == null
                    ? 'Chưa xác nhận thời điểm đọc.'
                    : 'Lần đọc: ${shortDate(source.observedAt!)} · ${shortTime(source.observedAt!)} (giờ thiết bị).',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuotaWindow extends StatelessWidget {
  const _QuotaWindow({
    required this.source,
    required this.window,
    required this.now,
  });
  final ProviderUsage source;
  final ProviderQuota window;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final remaining = source.remaining(window, now);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(window.windowLabel, style: text.titleMedium),
            Text(
              remaining == null
                  ? 'Cần cập nhật'
                  : '${remaining.toStringAsFixed(1)}% còn lại',
              style: text.titleLarge?.copyWith(
                color: remaining != null && remaining <= 25
                    ? AppColors.amber
                    : AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        if (remaining != null) ...[
          LinearProgressIndicator(
            value: remaining / 100,
            semanticsLabel:
                '${window.groupLabel}, ${window.windowLabel}, còn lại',
            semanticsValue: '${remaining.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Đã dùng ${window.usedPercent.toStringAsFixed(1)}%',
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        Text(
          'Mốc đặt lại từ nguồn: ${shortDate(window.resetsAt)} · ${shortTime(window.resetsAt)}',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
