import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/services/ledger_validation.dart';
import 'package:token_ledger/services/reporting_calendar.dart';
import 'package:token_ledger/services/usage_calculator.dart';

import 'support/schema_v2_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 21, 10);

  AIAccount account({
    String id = 'real',
    String zone = 'Asia/Ho_Chi_Minh',
    int day = 1,
  }) => createSchemaTestAccount(now, id: id, zone: zone, day: day);

  UsageSession usage(
    String id,
    DateTime date, {
    String accountId = 'real',
    int? cost = 0,
    DataSource source = DataSource.manual,
  }) => createSchemaTestUsage(
    date,
    id,
    accountId: accountId,
    cost: cost,
    source: source,
  );

  test(
    'cost basis breakdown sums once and keeps unknown out of known totals',
    () {
      UsageSession row(String id, int? cost, CostBasis basis) => UsageSession(
        id: id,
        accountId: 'real',
        title: id,
        purpose: Purpose.code,
        occurredAt: now,
        costMicros: cost,
        costBasis: basis,
      );
      final summary = UsageCalculator.summarize([
        row('actual', 2, CostBasis.actual),
        row('manual', 3, CostBasis.manual),
        row('old', 5, CostBasis.unspecified),
        row('unknown', null, CostBasis.unknown),
      ]);
      expect(summary.costMicros, 10);
      expect(summary.actualCostMicros, 2);
      expect(summary.manualCostMicros, 3);
      expect(summary.unspecifiedCostMicros, 5);
      expect(summary.unknownCost, 1);
    },
  );

  test('model/default purposes and quota collections round trip immutable with explicit clears', () {
    final defaults = [Purpose.review, Purpose.test];
    final q = QuotaSnapshot(
      window: '5 giờ',
      usedPercent: 0,
      observedAt: now,
      resetAt: now.add(const Duration(hours: 5)),
      sourceLabel: 'Trang usage',
      note: 'Quan sát thủ công',
    );
    final a = account().copyWith(
      defaultModelId: 'model-do-nguoi-dung-nhap',
      defaultPurposes: defaults,
      quotaWindows: [q],
    );
    defaults.clear();
    expect(a.defaultPurposes.length, 2);
    expect(() => a.defaultPurposes.clear(), throwsUnsupportedError);
    expect(() => a.quotaWindows.clear(), throwsUnsupportedError);
    final loaded = LedgerData.fromJson(
      LedgerData(accounts: [a], sessions: []).toJson(),
    ).accounts.single;
    expect(loaded.defaultModelId, a.defaultModelId);
    expect(loaded.quota!.sourceLabel, 'Trang usage');
    expect(loaded.quota!.unit, 'percent');
    expect(
      () => QuotaSnapshot.fromJson({...q.toJson(), 'unit': 'tokens'}),
      throwsFormatException,
    );
    expect(
      loaded
          .copyWith(
            clearDefaultModel: true,
            defaultPurposes: [],
            quotaWindows: [],
          )
          .defaultModelId,
      isNull,
    );
    expect(loaded.copyWith(quotaWindows: []).quotaWindows, isEmpty);
  });

  test('IANA timezone month boundary uses exact half-open UTC interval', () {
    final t = DateTime.utc(2026, 12, 31, 17);
    final rows = [
      usage('old', t.subtract(const Duration(microseconds: 1))),
      usage('start', t),
      usage('end', DateTime.utc(2027, 1, 1, 17)),
    ];
    expect(
      UsageCalculator.filter(
        rows,
        t,
        timezone: 'Asia/Ho_Chi_Minh',
      ).map((s) => s.id),
      ['start'],
    );
    expect(ReportingCalendar.dayKey(t, 'Asia/Ho_Chi_Minh'), '01/01/2027');
    expect(ReportingCalendar.dayKey(t, 'UTC'), '31/12/2026');
  });

  test(
    'custom cycle day31 clamps independently across leap February and year',
    () {
      final before = ReportingCalendar.cycle(
        DateTime.utc(2024, 2, 28),
        'UTC',
        31,
      );
      expect(before.start, DateTime.utc(2024, 1, 31));
      expect(before.end, DateTime.utc(2024, 2, 29));
      final after = ReportingCalendar.cycle(
        DateTime.utc(2024, 2, 29),
        'UTC',
        31,
      );
      expect(after.start, DateTime.utc(2024, 2, 29));
      expect(after.end, DateTime.utc(2024, 3, 31));
      final year = ReportingCalendar.cycle(DateTime.utc(2027, 1, 1), 'UTC', 15);
      expect(year.start, DateTime.utc(2026, 12, 15));
      expect(year.end, DateTime.utc(2027, 1, 15));
    },
  );

  test('IANA day boundaries honor DST 23h/25h instead of fixed24h', () {
    final spring = ReportingCalendar.wall('America/New_York', 2026, 3, 8);
    final springEnd = ReportingCalendar.wall('America/New_York', 2026, 3, 9);
    expect(springEnd.difference(spring).inHours, 23);
    final fall = ReportingCalendar.wall('America/New_York', 2026, 11, 1);
    final fallEnd = ReportingCalendar.wall('America/New_York', 2026, 11, 2);
    expect(fallEnd.difference(fall).inHours, 25);
    final a = account(zone: 'America/New_York', day: 8);
    final rows = [
      usage('before', spring.subtract(const Duration(microseconds: 1))),
      usage('exact', spring),
      usage('tomorrow', springEnd),
    ];
    expect(
      UsageCalculator.dailyCosts(rows, spring, timezone: a.timezone).last,
      0,
    );
    expect(
      UsageCalculator.filter(
        rows,
        spring,
        timezone: a.timezone,
      ).map((s) => s.id),
      ['exact', 'before'],
    );
  });

  test('invalid zone/cycle, duplicate windows/purposes and dishonest cost/source are rejected', () {
    expect(
      () => LedgerValidation.account(account(zone: 'Made/Up')),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.account(account(day: 0)),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.account(account(day: 32)),
      throwsArgumentError,
    );
    final q = QuotaSnapshot(
      window: 'Week',
      usedPercent: 0,
      observedAt: now,
      resetAt: now.add(const Duration(days: 1)),
    );
    expect(
      () => LedgerValidation.account(account().copyWith(quotaWindows: [q, q])),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.account(
        account().copyWith(defaultPurposes: [Purpose.code, Purpose.code]),
      ),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.usage(
        UsageSession(
          id: 'x',
          accountId: 'real',
          title: 'Test',
          purpose: Purpose.code,
          occurredAt: now,
          costBasis: CostBasis.actual,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => LedgerValidation.usage(
        UsageSession(
          id: 'x',
          accountId: 'real',
          title: 'Test',
          purpose: Purpose.code,
          occurredAt: now,
          dataSource: DataSource.demo,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('preferred metric honors known zero, uses count for unknown costs', () {
    expect(
      UsageCalculator.preferredMetric([usage('x', now, cost: null)]),
      UsageMetric.sessions,
    );
    expect(
      UsageCalculator.preferredMetric([usage('x', now, cost: 0)]),
      UsageMetric.cost,
    );
  });
}
