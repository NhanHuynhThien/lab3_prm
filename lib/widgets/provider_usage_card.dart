import 'package:flutter/material.dart';

import '../models/provider_usage.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'provider_brand_icon.dart';
import 'provider_model_rows.dart';
import 'provider_quota_metric.dart';

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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProviderBrandIcon(usage.id, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usage.name, style: text.titleLarge),
                    Text(
                      usage.observedAt == null
                          ? usage.source
                          : '${usage.source} · ${shortDate(usage.observedAt!)} ${shortTime(usage.observedAt!)}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusTag(
                usage.status == 'error'
                    ? 'Tạm ngắt'
                    : usage.status != 'ready'
                    ? 'Cần kết nối'
                    : usage.stale(now)
                    ? 'Dữ liệu cũ'
                    : 'Đã đọc',
                neutral: usage.status != 'ready' || usage.stale(now),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Metric(usage.tokenLabel, compactTokens(usage.totalTokens)),
              _Metric('Gói', usage.plan ?? 'Chưa xác nhận'),
              if (usage.id == 'claude') ...[
                _Metric('Context hiện tại', compactTokens(usage.contextTokens)),
                _Metric('Ước tính phiên', money(usage.estimatedCostMicros)),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text(
            usage.windows.isEmpty
                ? 'Hạn mức hiện tại'
                : 'Hạn mức hiện tại · ${usage.windows.length}',
            style: text.titleMedium,
          ),
          const SizedBox(height: 12),
          if (usage.windows.isEmpty)
            Text('Nguồn này chưa cung cấp hạn mức.', style: text.bodySmall)
          else
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth >= 560
                    ? (box.maxWidth - 12) / 2
                    : box.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final window in usage.windows)
                      SizedBox(
                        width: width,
                        child: ProviderQuotaMetric(
                          usage: usage,
                          window: window,
                          now: now,
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          Text(
            usage.id == 'claude'
                ? '${usage.coverage} Ước tính theo usage API của phiên, không phải hoá đơn thuê bao.'
                : usage.coverage,
            style: text.bodySmall,
          ),
          if (showModels) ...[
            const Divider(height: 40),
            ProviderModelRows(usage: usage),
          ],
        ],
      ),
    );
  }
}

/// One figure per tile so values never run into each other.
class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 140),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.neutral,
      borderRadius: BorderRadius.circular(AppSpace.controlRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
