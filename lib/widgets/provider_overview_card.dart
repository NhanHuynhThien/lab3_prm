import 'package:flutter/material.dart';

import '../models/provider_usage.dart';
import '../models/antigravity_analysis.dart';
import '../models/gemini_activity_summary.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'provider_brand_icon.dart';
import 'provider_model_preview.dart';
import 'provider_quota_metric.dart';

class ProviderOverviewCard extends StatelessWidget {
  const ProviderOverviewCard({
    super.key,
    required this.name,
    required this.usage,
    required this.now,
    required this.onDetails,
    this.activity,
  });
  final String name;
  final ProviderUsage? usage;
  final DateTime now;
  final VoidCallback onDetails;
  final GeminiActivitySummary? activity;

  @override
  Widget build(BuildContext context) {
    final row = usage;
    final ready = row?.status == 'ready';
    final quotas = [...?row?.windows]
      ..sort((a, b) => b.usedPercent.compareTo(a.usedPercent));
    final highlighted = row?.id == 'antigravity'
        ? antigravityGroups(
            row!,
            now,
          ).map((g) => g.limiting ?? g.windows.first).toList()
        : quotas.take(2).toList();
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (row != null)
                ProviderBrandIcon(row.id, size: 22, framed: false),
              Text(name, style: text.titleLarge),
              StatusTag(
                ready
                    ? quotas.isNotEmpty && row!.stale(now)
                          ? 'Cần cập nhật'
                          : 'Có số liệu'
                    : row?.status == 'error'
                    ? 'Tạm ngắt'
                    : 'Chưa kết nối',
                neutral: !ready,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ready
                ? '${row!.source} · cập nhật ${shortTime(row.observedAt!)}'
                : row?.coverage ?? 'Kết nối nguồn để xem số liệu.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 24),
          if (!ready) ...[
            const Icon(Icons.hub_outlined, size: 32, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('Chưa đủ dữ liệu để đánh giá', style: text.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Kết nối nguồn hoặc nhập bản xuất của bạn để xem thống kê thực.',
            ),
          ] else if (row!.id == 'gemini-web' && activity != null) ...[
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _Number('Hoạt động · 30 ngày', '${activity!.activityCount}'),
                _Number('Ngày có sử dụng · UTC', '${activity!.activeDays}'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Bản xuất không cung cấp token hay hạn mức. Xem tần suất theo ngày trong Phân tích.',
            ),
          ] else ...[
            if (quotas.isNotEmpty) ...[
              Text('Hạn mức cần theo dõi', style: text.titleMedium),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, box) {
                  final width =
                      box.maxWidth >= 560 &&
                          MediaQuery.textScalerOf(context).scale(14) < 22
                      ? (box.maxWidth - 16) / 2
                      : box.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final quota in highlighted)
                        SizedBox(
                          width: width,
                          child: ProviderQuotaMetric(
                            usage: row,
                            window: quota,
                            now: now,
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (quotas.length > highlighted.length)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Còn ${quotas.length - highlighted.length} hạn mức trong chi tiết nguồn.',
                    style: text.bodySmall,
                  ),
                ),
              const SizedBox(height: 24),
            ],
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _Number(row.tokenLabel, compactTokens(row.totalTokens)),
                if (row.models.isNotEmpty)
                  _Number('Model có ghi nhận', '${row.models.length}'),
              ],
            ),
            if (row.models.isNotEmpty) ...[
              const Divider(height: 32),
              ProviderModelPreview(usage: row),
            ],
            const SizedBox(height: 16),
            Text(row.coverage, style: text.bodySmall),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDetails,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Kết nối và xem số liệu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Number extends StatelessWidget {
  const _Number(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 6),
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
    ],
  );
}
