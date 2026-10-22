import '../models/ledger.dart';
import 'reporting_calendar.dart';

class ManualReportProjection {
  ManualReportProjection({
    required LedgerData data,
    required DateTime now,
    required String period,
    required DataScope scope,
  }) {
    final local = ReportingCalendar.at(now, data.reportingTimezone);
    final start = switch (period) {
      'Tháng này' => ReportingCalendar.wall(
        data.reportingTimezone,
        local.year,
        local.month,
        1,
      ),
      '30 ngày qua' => ReportingCalendar.wall(
        data.reportingTimezone,
        local.year,
        local.month,
        local.day - 29,
      ),
      _ => null,
    };
    sessions = List.unmodifiable(
      data.sessions.where(
        (s) =>
            !s.isDemo &&
            scope.includes(s) &&
            !s.occurredAt.isAfter(now) &&
            (start == null || !s.occurredAt.isBefore(start)),
      ),
    );
    accounts = List.unmodifiable(
      data.accounts.where(
        (a) => !a.isDemo && scope.includesAccount(a, sessions),
      ),
    );
    label = '$period · ${scope.label} · ${data.reportingTimezone}';
  }
  late final List<UsageSession> sessions;
  late final List<AIAccount> accounts;
  late final String label;
}
