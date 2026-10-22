import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/manual_report_projection.dart';

void main() {
  final now = DateTime.utc(2026, 10, 22, 12);
  UsageSession usage(String id, DateTime at) => UsageSession(
    id: id,
    accountId: 'a',
    title: id,
    purpose: Purpose.code,
    occurredAt: at,
  );
  final data = LedgerData(
    accounts: [],
    sessions: [
      usage('month', DateTime.utc(2026, 10, 1)),
      usage('30days', DateTime.utc(2026, 9, 23)),
      usage('old', DateTime.utc(2026, 9, 1)),
      usage('future', DateTime.utc(2026, 10, 23)),
    ],
  );
  test(
    'selected PDF period filters the actual data and excludes future entries',
    () {
      List<String> ids(String p) => ManualReportProjection(
        data: data,
        now: now,
        period: p,
        scope: DataScope.manual,
      ).sessions.map((s) => s.id).toList();
      expect(ids('Tháng này'), ['month']);
      expect(ids('30 ngày qua'), ['month', '30days']);
      expect(ids('Toàn bộ dữ liệu'), ['month', '30days', 'old']);
    },
  );
  test('month boundary follows selected reporting zone', () {
    final utc = DateTime.utc(2026, 10, 1, 0, 30);
    final d = LedgerData(
      reportingTimezone: 'America/Los_Angeles',
      accounts: [],
      sessions: [usage('sep', utc), usage('oct', DateTime.utc(2026, 10, 1, 8))],
    );
    expect(
      ManualReportProjection(
        data: d,
        now: now,
        period: 'Tháng này',
        scope: DataScope.manual,
      ).sessions.single.id,
      'oct',
    );
  });
}
