import '../models/ledger.dart';
import 'reporting_calendar.dart';

/// Deliberately fictional manual entries. These are not provider prices or balances.
LedgerData createDemoSeed(
  DateTime now, {
  String timezone = 'Asia/Ho_Chi_Minh',
}) {
  now = ReportingCalendar.at(now, timezone);
  final monthStart = ReportingCalendar.wall(timezone, now.year, now.month, 1);
  final accounts = [
    AIAccount(
      id: 'claude',
      alias: 'Claude cá nhân',
      provider: 'Anthropic',
      product: 'Claude',
      billingMode: BillingMode.subscription,
      plan: 'Cá nhân',
      budgetMicros: 20000000,
      createdAt: ReportingCalendar.instantUtc(monthStart),
      isDemo: true,
      dataSource: DataSource.demo,
      timezone: timezone,
      quota: QuotaSnapshot(
        source: DataSource.demo,
        window: '5 giờ',
        usedPercent: 65,
        observedAt: ReportingCalendar.instantUtc(now),
        resetAt: ReportingCalendar.instantUtc(
          now.add(const Duration(hours: 3)),
        ),
      ),
    ),
    AIAccount(
      id: 'codex',
      alias: 'Codex học tập',
      provider: 'OpenAI',
      product: 'Codex',
      billingMode: BillingMode.subscription,
      plan: 'Học tập',
      budgetMicros: 25000000,
      createdAt: ReportingCalendar.instantUtc(monthStart),
      isDemo: true,
      dataSource: DataSource.demo,
      timezone: timezone,
      quota: QuotaSnapshot(
        source: DataSource.demo,
        window: 'Hàng tuần',
        usedPercent: 40,
        observedAt: ReportingCalendar.instantUtc(now),
        resetAt: ReportingCalendar.instantUtc(now.add(const Duration(days: 3))),
      ),
    ),
    AIAccount(
      id: 'gemini',
      alias: 'Gemini nghiên cứu',
      provider: 'Google',
      product: 'Gemini',
      billingMode: BillingMode.api,
      plan: 'API',
      budgetMicros: 5000000,
      createdAt: ReportingCalendar.instantUtc(monthStart),
      isDemo: true,
      dataSource: DataSource.demo,
      timezone: timezone,
    ),
  ];
  final specs = <(String, String, Purpose, int?, int?)>[
    ('claude', 'Review kiến trúc Flutter', Purpose.review, 45000, 1240000),
    ('codex', 'Sửa lỗi Google Sign-In', Purpose.debug, 38000, 960000),
    ('claude', 'Phân tích yêu cầu Lab 3', Purpose.research, 32000, 2100000),
    ('codex', 'Dựng component thư viện', Purpose.code, 45000, 1800000),
    ('gemini', 'Tìm hiểu Riverpod', Purpose.learn, 8000, 300000),
    ('claude', 'Kiểm tra Firestore Rules', Purpose.review, 18000, 840000),
    ('codex', 'Viết unit test calculator', Purpose.test, 22000, 1200000),
    ('gemini', 'Tổng hợp tài liệu Firebase', Purpose.research, 10000, 400000),
    ('claude', 'Lên luồng quản lý quota', Purpose.design, 26000, 1500000),
    ('codex', 'Xây dựng màn hình phân tích', Purpose.code, 36000, 1900000),
    ('gemini', 'Ghi chú bài học Flutter', Purpose.write, 6000, 600000),
    ('gemini', 'Khám phá công cụ mới', Purpose.research, null, null),
  ];
  final sessions = <UsageSession>[];
  for (var i = 0; i < specs.length; i++) {
    final s = specs[i];
    // Stay in this month, including on the first day of a new month.
    final offset = (i * .7).floor().clamp(0, now.day - 1);
    final date = now.subtract(Duration(days: offset, minutes: i * 13));
    final occurred = date.isBefore(monthStart) ? monthStart : date;
    final input = s.$4 == null ? null : s.$4! * 4 ~/ 5;
    sessions.add(
      UsageSession(
        id: 'seed-$i',
        accountId: s.$1,
        title: s.$2,
        purpose: s.$3,
        occurredAt: ReportingCalendar.instantUtc(occurred),
        inputTokens: input,
        outputTokens: s.$4 == null ? null : s.$4! - input!,
        costMicros: s.$5,
        dataSource: DataSource.demo,
        isDemo: true,
        costBasis: s.$5 == null ? CostBasis.unknown : CostBasis.manual,
        note: 'Dữ liệu demo giả định, không phải số liệu đồng bộ từ nhà cung cấp.',
      ),
    );
  }
  return LedgerData(
    accounts: accounts,
    sessions: sessions,
    reportingTimezone: timezone,
  );
}

LedgerData withoutDemo(LedgerData data) {
  final sessions = data.sessions.where((s) => !s.isDemo).toList();
  return data.copyWith(
    accounts: data.accounts
        .where((a) => !a.isDemo || sessions.any((s) => s.accountId == a.id))
        .toList(),
    sessions: sessions,
  );
}

LedgerData createDemoReset(
  LedgerData current,
  DateTime now,
  String Function() newId,
) {
  final retained = withoutDemo(current);
  final seed = createDemoSeed(now);
  final ids = {
    for (final a in seed.accounts)
      a.id: retained.account(a.id) == null ? a.id : newId(),
  };
  final accounts = [
    for (final a in seed.accounts)
      AIAccount(
        id: ids[a.id]!,
        alias: a.alias,
        provider: a.provider,
        product: a.product,
        billingMode: a.billingMode,
        plan: a.plan,
        createdAt: a.createdAt,
        budgetMicros: a.budgetMicros,
        isDemo: true,
        dataSource: DataSource.demo,
        timezone: a.timezone,
        quotaWindows: a.quotaWindows,
      ),
  ];
  final sessions = [
    for (final s in seed.sessions)
      UsageSession(
        id: retained.sessions.any((old) => old.id == s.id) ? newId() : s.id,
        accountId: ids[s.accountId]!,
        title: s.title,
        purpose: s.purpose,
        occurredAt: s.occurredAt,
        inputTokens: s.inputTokens,
        outputTokens: s.outputTokens,
        costMicros: s.costMicros,
        costBasis: s.costBasis,
        dataSource: DataSource.demo,
        isDemo: true,
        note: s.note,
      ),
  ];
  return retained.copyWith(
    accounts: [...retained.accounts, ...accounts],
    sessions: [...retained.sessions, ...sessions],
  );
}
