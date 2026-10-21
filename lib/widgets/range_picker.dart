import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';

class RangePicker extends ConsumerWidget {
  const RangePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<UsageRange>(
        tooltip: 'Chọn khoảng thời gian',
        initialValue: ref.watch(rangeProvider),
        onSelected: (value) => ref.read(rangeProvider.notifier).select(value),
        itemBuilder: (_) => UsageRange.values
            .map((v) => PopupMenuItem(value: v, child: Text(v.label)))
            .toList(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                ref.watch(rangeProvider).label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      );
}
