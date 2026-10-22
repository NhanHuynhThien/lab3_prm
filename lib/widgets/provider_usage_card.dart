import 'package:flutter/material.dart';

import '../models/provider_usage.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'provider_model_rows.dart';

class ProviderUsageCard extends StatelessWidget {
  const ProviderUsageCard({
    super.key,
    required this.usage,
    required this.now,
    this.showModels = true,
  });
  final ProviderUsage usage;
  final DateTime now;
  final bool showModels;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(usage.name, style: Theme.of(context).textTheme.titleLarge),
            StatusTag(
              usage.status == 'error'
                  ? 'Nguồn tạm ngắt'
                  : usage.status != 'ready'
                  ? 'Cần kết nối nguồn'
                  : usage.stale(now)
                  ? 'Dữ liệu cũ'
                  : 'Đã đọc nguồn',
              neutral: usage.status != 'ready' || usage.stale(now),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(usage.source, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(usage.coverage),
        const SizedBox(height: 16),
        _Metric('Gói do nguồn xác nhận', usage.plan ?? 'Chưa xác nhận'),
        _Metric(
          usage.id == 'codex'
              ? 'Token lifetime · server'
              : usage.id == 'antigravity'
              ? 'Token IDE'
              : 'Token CLI · 30 ngày',
          compactTokens(usage.totalTokens),
        ),
        if (usage.id == 'claude') ...[
          _Metric(
            'Token input context hiện tại',
            compactTokens(usage.contextTokens),
          ),
          _Metric('Ước tính phiên Code', money(usage.estimatedCostMicros)),
          const Text(
            'Ước tính theo usage API của phiên, không phải hoá đơn thuê bao.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
        const _Metric('Phí thuê bao / phí đã charge', 'Chưa có nguồn'),
        if (usage.windows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Chưa có số liệu hạn mức từ nguồn.'),
          ),
        for (final window in usage.windows) ...[
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final remaining = usage.remaining(window, now);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(window.label),
                  const SizedBox(height: 6),
                  Text(
                    remaining == null
                        ? 'Snapshot đã cũ/hết kỳ, cần cập nhật'
                        : 'Đã dùng ${window.usedPercent.toStringAsFixed(1)}% · Còn ${remaining.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (remaining != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: window.usedPercent / 100,
                      semanticsLabel: '${usage.name}, ${window.label}, đã dùng',
                      semanticsValue:
                          '${window.usedPercent.toStringAsFixed(1)}%',
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Đặt lại: ${shortDate(window.resetsAt)} ${shortTime(window.resetsAt)}',
                  ),
                ],
              );
            },
          ),
        ],
        if (usage.observedAt != null) ...[
          const SizedBox(height: 16),
          Text(
            'Nguồn cập nhật ${shortDate(usage.observedAt!)} ${shortTime(usage.observedAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        if (showModels) ProviderModelRows(usage: usage),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        Text('$label:', style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
