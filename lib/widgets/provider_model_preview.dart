import 'package:flutter/material.dart';

import '../models/provider_usage.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ProviderModelPreview extends StatelessWidget {
  const ProviderModelPreview({super.key, required this.usage});
  final ProviderUsage usage;
  @override
  Widget build(BuildContext context) {
    final models = [...usage.models]
      ..sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model đã sử dụng',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'Token ghi nhận theo nguồn, không phải phí đã charge.',
          style: TextStyle(color: AppColors.muted),
        ),
        for (final model in models.take(3)) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, box) {
              final label = Text(
                model.model,
                style: Theme.of(context).textTheme.titleSmall,
              );
              final value = Text(
                '${compactTokens(model.totalTokens)} token',
                style: Theme.of(context).textTheme.bodyMedium,
              );
              return box.maxWidth < 350 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, const SizedBox(height: 4), value],
                    )
                  : Row(
                      children: [
                        Expanded(child: label),
                        const SizedBox(width: 16),
                        value,
                      ],
                    );
            },
          ),
        ],
        if (models.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Chưa có thống kê theo model.'),
          ),
        if (models.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Còn ${models.length - 3} model trong chi tiết nguồn.'),
          ),
      ],
    );
  }
}
