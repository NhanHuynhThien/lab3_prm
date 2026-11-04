import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'data_scope_picker.dart';

/// Range + scope + timezone on a single line; scrolls instead of wrapping.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [RangePicker(), SizedBox(width: 8), DataScopePicker()],
    ),
  );
}

/// Shared look for the dropdown filters so they line up.
class FilterButton extends StatelessWidget {
  const FilterButton(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: AppSpace.touch),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(AppSpace.controlRadius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 4),
        const Icon(Icons.expand_more, size: 18),
      ],
    ),
  );
}

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
        child: FilterButton(
          ref.watch(rangeProvider).label,
          icon: Icons.calendar_today_outlined,
        ),
      );
}
