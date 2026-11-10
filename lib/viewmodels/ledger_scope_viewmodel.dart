import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/reporting_calendar.dart';
import '../services/usage_calculator.dart';
import 'ledger_viewmodel.dart';

class RangeViewModel extends Notifier<UsageRange> {
  @override
  UsageRange build() => UsageRange.month;
  void select(UsageRange range) => state = range;

  /// Calendar days from the date range picker, both ends inclusive.
  void selectDays(DateTime first, DateTime last) {
    ref.read(customDaysProvider.notifier).set((first: first, last: last));
    state = UsageRange.custom;
  }
}

typedef CalendarDays = ({DateTime first, DateTime last});

class CustomDaysViewModel extends Notifier<CalendarDays?> {
  @override
  CalendarDays? build() => null;
  void set(CalendarDays days) => state = days;
}

final customDaysProvider = NotifierProvider<CustomDaysViewModel, CalendarDays?>(
  CustomDaysViewModel.new,
);

/// Bounds of a picked range in the reporting timezone: start of the first
/// day to the start of the day after the last one. Null for preset ranges.
({DateTime start, DateTime end})? customBounds(Ref ref, String timezone) {
  final days = ref.watch(customDaysProvider);
  if (ref.watch(rangeProvider) != UsageRange.custom || days == null) {
    return null;
  }
  final f = days.first, l = days.last;
  return (
    start: ReportingCalendar.wall(timezone, f.year, f.month, f.day),
    end: ReportingCalendar.wall(timezone, l.year, l.month, l.day + 1),
  );
}

final rangeProvider = NotifierProvider<RangeViewModel, UsageRange>(
  RangeViewModel.new,
);

final filteredSessionsProvider = Provider.autoDispose<List<UsageSession>>((
  ref,
) {
  final data = ref.watch(ledgerProvider).asData?.value;
  final timezone = data?.reportingTimezone ?? 'device';
  final custom = customBounds(ref, timezone);
  return UsageCalculator.filter(
    data?.sessions ?? [],
    ref.watch(nowProvider),
    range: ref.watch(rangeProvider),
    timezone: timezone,
    scope: ref.watch(effectiveDataScopeProvider),
    periodStart: custom?.start,
    periodEnd: custom?.end,
  );
});

class DataScopeViewModel extends Notifier<DataScope?> {
  @override
  DataScope? build() => null;
  void select(DataScope scope) => state = scope;
}

final dataScopeProvider = NotifierProvider<DataScopeViewModel, DataScope?>(
  DataScopeViewModel.new,
);

final effectiveDataScopeProvider = Provider.autoDispose<DataScope>((ref) {
  final selected = ref.watch(dataScopeProvider);
  if (selected != null) return selected;
  final data = ref.watch(ledgerProvider).asData?.value;
  if ((data?.sessions.any((s) => DataScope.manual.includes(s)) ?? false) ||
      (data?.accounts.any(
            (a) =>
                a.dataSource == DataSource.manual ||
                a.dataSource == DataSource.companion,
          ) ??
          false)) {
    return DataScope.manual;
  }
  if ((data?.sessions.any((s) => DataScope.legacy.includes(s)) ?? false) ||
      (data?.accounts.any((a) => a.dataSource == DataSource.legacy) ?? false)) {
    return DataScope.legacy;
  }
  // Retain schema compatibility for old local snapshots; no sandbox route exists.
  return data?.accounts.any((a) => a.isDemo) == true
      ? DataScope.demo
      : DataScope.manual;
});
