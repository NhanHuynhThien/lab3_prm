import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class QuotaTimePickers extends StatelessWidget {
  const QuotaTimePickers({
    super.key,
    required this.reset,
    required this.observed,
    required this.now,
    required this.onResetChanged,
    required this.onObservedChanged,
  });

  final DateTime reset;
  final DateTime observed;
  final DateTime now;
  final ValueChanged<DateTime> onResetChanged;
  final ValueChanged<DateTime> onObservedChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        onPressed: () async {
          final lastDate = now.add(const Duration(days: 366));
          final date = await showDatePicker(
            context: context,
            initialDate: reset.isBefore(now)
                ? now
                : reset.isAfter(lastDate)
                ? lastDate
                : reset,
            firstDate: DateTime(now.year, now.month, now.day),
            lastDate: lastDate,
          );
          if (date == null || !context.mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(reset),
          );
          if (time != null && context.mounted) {
            onResetChanged(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          }
        },
        icon: const Icon(Icons.schedule),
        label: Text('Reset ${shortDate(reset)} lúc ${shortTime(reset)}'),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        icon: const Icon(Icons.visibility_outlined),
        label: Text(
          'Quan sát ${shortDate(observed)} lúc ${shortTime(observed)} · giờ thiết bị',
        ),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: observed.isAfter(now) ? now : observed,
            firstDate: DateTime(2020),
            lastDate: now,
          );
          if (date == null || !context.mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(observed),
          );
          if (time != null && context.mounted) {
            onObservedChanged(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          }
        },
      ),
    ],
  );
}
