import 'package:flutter/material.dart';

import '../models/provider_usage.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'provider_quota_metric.dart';
import 'provider_model_preview.dart';

class ProviderOverviewCard extends StatelessWidget {
  const ProviderOverviewCard({
    super.key,
    required this.name,
    required this.usage,
    required this.now,
    required this.onDetails,
    this.unsupported = false,
  });
  final String name;
  final ProviderUsage? usage;
  final DateTime now;
  final VoidCallback onDetails;
  final bool unsupported;

  @override
  Widget build(BuildContext context) {
    final row = usage;
    final ready = row?.status == 'ready';
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              StatusTag(
                ready
                    ? row!.plan ?? 'Đã kết nối'
                    : unsupported
                    ? 'Chưa hỗ trợ'
                    : 'Chưa có dữ liệu',
                neutral: !ready,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ready
                ? '${row!.source} · ${shortTime(row.observedAt!)}'
                : unsupported
                ? 'Bộ kết nối Antigravity chưa được triển khai.'
                : row?.status == 'error'
                ? 'Không đọc được nguồn. Hãy kiểm tra kết nối.'
                : 'Cần kết nối nguồn sử dụng của $name.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (ready) ...[
            if (row!.windows.isNotEmpty)
              LayoutBuilder(
                builder: (context, box) {
                  final stack =
                      box.maxWidth < 260 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20;
                  final tiles = [
                    for (final w in row.windows)
                      ProviderQuotaMetric(usage: row, window: w, now: now),
                  ];
                  return stack
                      ? Column(
                          children: [
                            for (final tile in tiles) ...[
                              tile,
                              const SizedBox(height: 12),
                            ],
                          ],
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final tile in tiles)
                              SizedBox(
                                width: (box.maxWidth - 16) / 2,
                                child: tile,
                              ),
                          ],
                        );
                },
              )
            else
              const Text('Hạn mức còn lại: chưa có nguồn xác nhận.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _Number(
                  row.id == 'claude'
                      ? 'Token context'
                      : row.id == 'codex'
                      ? 'Token lifetime · server'
                      : 'Token CLI · 30 ngày',
                  _tokens(
                    row.id == 'claude' ? row.contextTokens : row.totalTokens,
                  ),
                ),
                _Number('Model ghi nhận', '${row.models.length}'),
              ],
            ),
            const SizedBox(height: 24),
            ProviderModelPreview(usage: row),
            const SizedBox(height: 20),
            const Text(
              'Phí đã thanh toán: chưa có nguồn hóa đơn.',
              style: TextStyle(color: AppColors.muted),
            ),
          ] else ...[
            Icon(
              unsupported ? Icons.extension_outlined : Icons.cloud_off_outlined,
              size: 32,
              color: AppColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              unsupported
                  ? 'Chưa đọc được số liệu Antigravity'
                  : 'Chưa thể thống kê $name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              unsupported
                  ? 'Sẽ hiển thị model và quota khi có bộ kết nối thật.'
                  : 'Chưa có số liệu không có nghĩa là bạn chưa sử dụng. '
                        'Đăng nhập Google chỉ xác định tài khoản TokenLedger.',
            ),
          ],
          if (row != null && !ready && row.models.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Model từ bản đã đọc trước đó'),
            ProviderModelPreview(usage: row),
          ],
          const SizedBox(height: 20),
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

String _tokens(int? value) => value != null && value >= 1000000000
    ? '${(value / 1000000000).toStringAsFixed(2)}B'
    : compactTokens(value);
