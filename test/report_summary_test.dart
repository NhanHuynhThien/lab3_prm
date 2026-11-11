import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ai_account.dart';
import 'package:token_ledger/models/ledger_enums.dart';
import 'package:token_ledger/models/quota_snapshot.dart';
import 'package:token_ledger/models/usage_session.dart';
import 'package:token_ledger/services/pdf_report_service.dart';
import 'package:token_ledger/services/report_summary.dart';

UsageSession _s(
  String id,
  DateTime at, {
  int? tokens,
  int? cost,
  String? model,
  Purpose purpose = Purpose.code,
}) => UsageSession(
  id: id,
  accountId: 'auto-codex',
  title: 'Task $id',
  purpose: purpose,
  occurredAt: at,
  inputTokens: tokens,
  outputTokens: tokens == null ? null : 0,
  costMicros: cost,
  modelId: model,
  dataSource: DataSource.companion,
);

void main() {
  final day1 = DateTime.utc(2026, 11, 1, 3);
  final day2 = DateTime.utc(2026, 11, 2, 3);

  test('groups by day, model and purpose without inventing zero', () {
    final summary = ReportSummary.of([
      _s('auto-a', day2, tokens: 300, model: 'gpt-5'),
      _s('auto-b', day1, tokens: 100, model: 'gpt-5'),
      _s('auto-c', day1, model: 'o3', purpose: Purpose.debug),
    ], timezone: 'Asia/Ho_Chi_Minh');

    expect(summary.sessionCount, 3);
    expect(summary.tokens, 400);
    expect(summary.costMicros, isNull);
    expect(summary.hasCost, isFalse);
    expect(summary.autoCount, 3);
    expect(summary.sessions.first.id, 'auto-a', reason: 'newest first');
    expect(summary.byDay.map((r) => r.label), ['01/11/2026', '02/11/2026']);
    expect(summary.byDay.first.tokens, 100);
    expect(summary.byModel.first.label, 'gpt-5');
    expect(summary.byModel.last.tokens, isNull);
    expect(summary.byPurpose.map((r) => r.label), [
      Purpose.code.label,
      Purpose.debug.label,
    ]);
  });

  test('an account with no sessions totals zero, unknown-only stays null', () {
    final account = AIAccount(
      id: 'auto-codex',
      alias: 'Codex',
      provider: 'OpenAI',
      product: 'Codex',
      billingMode: BillingMode.subscription,
      plan: '',
      createdAt: day1,
    );
    expect(ReportSummary.of([]).account(account).tokens, 0);
    expect(
      ReportSummary.of([_s('auto-x', day1)]).account(account).tokens,
      isNull,
    );
  });

  test('PDF renders auto sessions with quota and no cost', () async {
    final account = AIAccount(
      id: 'auto-codex',
      alias: 'Codex',
      provider: 'OpenAI',
      product: 'Codex',
      billingMode: BillingMode.subscription,
      plan: '',
      createdAt: day1,
      quotaWindows: [
        QuotaSnapshot(
          window: '5 giờ',
          usedPercent: 40,
          observedAt: day2,
          resetAt: day2.add(const Duration(hours: 3)),
          source: DataSource.companion,
        ),
      ],
    );
    final bytes = await const PdfReportService().generateReportBytes(
      userEmail: null,
      periodLabel: 'Tháng này',
      accounts: [account],
      sessions: [
        for (var i = 0; i < 40; i++)
          _s('auto-$i', day1.add(Duration(days: i)), tokens: 1000, model: 'm'),
      ],
      timezone: 'Asia/Ho_Chi_Minh',
    );
    expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
  });

  test('a table longer than one page still breaks across pages', () async {
    final accounts = [
      for (var i = 0; i < 60; i++)
        AIAccount(
          id: 'acc-$i',
          alias: 'Account $i',
          provider: 'OpenAI',
          product: 'API',
          billingMode: BillingMode.api,
          plan: '',
          createdAt: day1,
        ),
    ];
    final bytes = await const PdfReportService().generateReportBytes(
      userEmail: null,
      periodLabel: 'Toàn bộ dữ liệu',
      accounts: accounts,
      sessions: const [],
    );
    expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
  });
}
