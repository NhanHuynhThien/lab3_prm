import 'package:flutter/material.dart';

import '../models/provider_usage.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ProviderModelRows extends StatelessWidget {
  const ProviderModelRows({super.key, required this.usage});
  final ProviderUsage usage;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Model đã dùng · ${usage.models.length}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(usage.modelsCoverage, style: Theme.of(context).textTheme.bodySmall),
      if (usage.models.isEmpty) ...[
        const SizedBox(height: 8),
        const Text('Chưa có model được ghi nhận trong nguồn này.'),
      ],
      for (final model in usage.models) ...[
        const Divider(height: 24),
        Text(model.model, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text('Tổng: ${model.totalTokens} token'),
            Text('Input: ${model.inputTokens ?? 'Chưa biết'}'),
            Text('Output: ${model.outputTokens ?? 'Chưa biết'}'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Chi phí ước tính: ${money(model.estimatedCostMicros)}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ],
  );
}
