import '../models/ledger.dart';
import 'reporting_calendar.dart';

class ManualReportProjection {
  ManualReportProjection({
    required LedgerData data,
    required DateTime now,
    required String period,
    required DataScope scope,
  }) {
    final zone = data.reportingTimezone;
    final local = ReportingCalendar.at(now, zone);
    final start = switch (period) {
      'Tháng này' => ReportingCalendar.wall(zone, local.year, local.month, 1),
      'Tháng trước' => ReportingCalendar.wall(
        zone,
        local.year,
        local.month - 1,
        1,
      ),
      '30 ngày qua' => ReportingCalendar.wall(
        zone,
        local.year,
        local.month,
        local.day - 29,
      ),
      _ => null,
    };
    final end = period == 'Tháng trước'
        ? ReportingCalendar.wall(zone, local.year, local.month, 1)
        : null;
    sessions = List.unmodifiable(
      data.sessions.where(
        (s) =>
            !s.isDemo &&
            scope.includes(s) &&
            !s.occurredAt.isAfter(now) &&
            (start == null || !s.occurredAt.isBefore(start)) &&
            (end == null || s.occurredAt.isBefore(end)),
      ),
    );
    accounts = List.unmodifiable(
      data.accounts.where(
        (a) => !a.isDemo && scope.includesAccount(a, sessions),
      ),
    );
    timezone = zone;
    // Real dates: "Tháng này" alone means nothing when the PDF is reread later.
    final dates = start == null
        ? ''
        : ' (${ReportingCalendar.dayKey(start, zone)} – ${ReportingCalendar.dayKey(end?.subtract(const Duration(seconds: 1)) ?? now, zone)})';
    label = '$period$dates · ${scope.label} · $zone';
  }
  late final List<UsageSession> sessions;
  late final List<AIAccount> accounts;
  late final String label, timezone;
}
