import 'package:flutter/material.dart';

import '../models/provider_usage.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ProviderQuotaMetric extends StatelessWidget {
  const ProviderQuotaMetric({
    super.key,
    required this.usage,
    required this.window,
    required this.now,
  });
  final ProviderUsage usage;
  final ProviderQuota window;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final remaining = usage.remaining(window, now);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            window.displayLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              remaining == null
                  ? 'Cần cập nhật'
                  : '${remaining.toStringAsFixed(1)}%',
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: remaining == null ? 24 : 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            remaining == null
                ? 'Snapshot đã cũ hoặc hết kỳ'
                : 'hạn mức còn lại',
          ),
          if (remaining != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: remaining / 100,
                minHeight: 5,
                semanticsLabel: '${usage.name}, ${window.label}, còn lại',
                semanticsValue: '${remaining.toStringAsFixed(1)}%',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Đặt lại ${shortDate(window.resetsAt)} · ${shortTime(window.resetsAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
