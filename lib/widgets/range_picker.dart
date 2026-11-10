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

String _dd(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// What the period filter shows: a preset name or the picked days.
String rangeLabelOf(UsageRange range, CalendarDays? days) =>
    range == UsageRange.custom && days != null
    ? '${_dd(days.first)} – ${_dd(days.last)}'
    : range.label;

/// Period filter: opens the date range picker straight away. The label
/// keeps preset names until the user picks days on the calendar.
class RangePicker extends ConsumerWidget {
  const RangePicker({super.key});

  /// Calendar days the current filter covers, for the picker's preselection.
  static DateTimeRange _shown(
    UsageRange range,
    CalendarDays? days,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (range) {
      UsageRange.custom when days != null => DateTimeRange(
        start: days.first,
        end: days.last,
      ),
      UsageRange.lastMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0),
      ),
      UsageRange.week => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      UsageRange.all => DateTimeRange(start: DateTime(2020), end: today),
      _ => DateTimeRange(start: DateTime(now.year, now.month, 1), end: today),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(rangeProvider);
    final days = ref.watch(customDaysProvider);
    final label = rangeLabelOf(range, days);
    return Semantics(
      button: true,
      label: 'Chọn khoảng thời gian, đang xem $label',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        onTap: () async {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final shown = _shown(range, days, now);
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: today,
            initialDateRange: DateTimeRange(
              start: shown.start,
              end: shown.end.isAfter(today) ? today : shown.end,
            ),
            helpText: 'Chọn khoảng ngày',
            saveText: 'Áp dụng',
          );
          if (picked != null) {
            ref
                .read(rangeProvider.notifier)
                .selectDays(picked.start, picked.end);
          }
        },
        child: FilterButton(label, icon: Icons.calendar_today_outlined),
      ),
    );
  }
}
