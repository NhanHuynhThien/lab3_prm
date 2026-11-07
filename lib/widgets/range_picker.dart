import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'data_scope_picker.dart';

/// Keeps the dashboard actions within the available width.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, this.leading});
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (leading != null) ...[
            Expanded(child: leading!),
            const SizedBox(width: 8),
          ],
          const Expanded(child: RangePicker()),
          const SizedBox(width: 8),
          const DataScopePicker(compact: true),
        ],
      ),
    );
  }
}

/// Shared look for the dropdown filters so they line up.
class FilterButton extends StatelessWidget {
  const FilterButton(this.label, {super.key, this.icon, this.active = false});
  final String label;
  final IconData? icon;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: AppSpace.button),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: active ? AppColors.soft : AppColors.surface,
      border: Border.all(color: active ? AppColors.primary : AppColors.line),
      borderRadius: BorderRadius.circular(AppSpace.controlRadius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
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
