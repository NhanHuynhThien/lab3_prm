import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:token_ledger/models/export_report.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/models/notification_item.dart';
import 'package:token_ledger/services/analytics_service.dart';
import 'package:token_ledger/services/manual_report_projection.dart';
import 'package:token_ledger/services/notification_service.dart';
import 'package:token_ledger/services/pdf_report_service.dart';
import 'package:token_ledger/services/report_management_service.dart';
import 'package:token_ledger/services/storage_service.dart';

class _FakePdf extends PdfReportService {
  const _FakePdf({this.saveFails = false, this.openType = ResultType.done});
  final bool saveFails;
  final ResultType openType;
  @override
  Future<Uint8List> generateReportBytes({
    required String? userEmail,
    required String periodLabel,
    required List<AIAccount> accounts,
    required List<UsageSession> sessions,
    String timezone = 'device',
  }) async => Uint8List(1);
  @override
  Future<String?> savePdfLocally({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (saveFails) throw Exception('disk full');
    return '/tmp/$fileName';
  }

  @override
  Future<OpenResult?> openFile(String filePath) async =>
      OpenResult(type: openType);
}

class _Inbox implements NotificationStore {
  @override
  Future<List<NotificationItem>> inbox(String uid) async => [
    NotificationItem(
      id: 'n',
      title: 'T',
      body: 'B',
      receivedAt: DateTime.utc(2026),
    ),
  ];
  @override
  Future<void> read(String uid, String id) async {}
  @override
  Future<void> register(String uid, String token) async {}
  @override
  Future<void> unregister(String uid) async {}
}

void main() {
  final now = DateTime.utc(2026, 11, 20, 5);
  UsageSession usage(String id, DateTime at) => UsageSession(
    id: id,
    accountId: 'a',
    title: id,
    purpose: Purpose.code,
    occurredAt: at,
  );
  ManualReportProjection report(String period) => ManualReportProjection(
    data: LedgerData(
      reportingTimezone: 'UTC',
      accounts: [],
      sessions: [
        usage('nov', DateTime.utc(2026, 11, 2)),
        usage('oct', DateTime.utc(2026, 10, 31, 23)),
        usage('sep', DateTime.utc(2026, 9, 30)),
      ],
    ),
    now: now,
    period: period,
    scope: DataScope.manual,
  );

  ReportManagementService service(PdfReportService pdf) =>
      ReportManagementService(
        pdfService: pdf,
        storageService: StorageService(null),
        analyticsService: AnalyticsService(null),
      )..bindOwner('A');

  Future<ExportReport> make(ReportManagementService s) => s.generateReport(
    periodLabel: 'QA',
    accounts: const [],
    sessions: const [],
    userEmail: null,
  );

  test('last-month report covers only that month and names its dates', () {
    final r = report('Tháng trước');
    expect(r.sessions.map((s) => s.id), ['oct']);
    expect(r.label, contains('01/10/2026 – 31/10/2026'));
    expect(r.timezone, 'UTC');
  });

  test('this-month report names dates up to today', () {
    expect(report('Tháng này').label, contains('01/11/2026 – 20/11/2026'));
  });

  test('whole-history report has no invented date range', () {
    final r = report('Toàn bộ dữ liệu');
    expect(r.sessions, hasLength(3));
    expect(r.label, startsWith('Toàn bộ dữ liệu ·'));
  });

  test('a failed save fails the report instead of claiming success', () async {
    final s = service(const _FakePdf(saveFails: true));
    await expectLater(make(s), throwsException);
    expect(s.reports, isEmpty);
  });

  test('a PDF that cannot be opened reports why', () async {
    final s = service(const _FakePdf(openType: ResultType.noAppToOpen));
    final made = await make(s);
    await expectLater(
      s.openLocalReport(made.id),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('ứng dụng đọc PDF'),
        ),
      ),
    );
  });

  test('a PDF that opens raises nothing', () async {
    final s = service(const _FakePdf());
    await s.openLocalReport((await make(s)).id);
  });

  test('limiting quota is the closest live window, never an expired one', () {
    QuotaSnapshot q(String name, int used, DateTime reset) => QuotaSnapshot(
      window: name,
      usedPercent: used,
      observedAt: now.subtract(const Duration(days: 9)),
      resetAt: reset,
    );
    final later = now.add(const Duration(days: 1));
    final a = AIAccount(
      id: 'a',
      alias: 'A',
      provider: 'OpenAI',
      product: 'Codex',
      billingMode: BillingMode.api,
      plan: '',
      createdAt: now,
      quotaWindows: [
        q('Tuần', 20, later),
        q('5 giờ', 70, later),
        q('Hết hạn', 99, now.subtract(const Duration(days: 1))),
      ],
    );
    expect(a.limitingQuota(now)!.window, '5 giờ');
    expect(a.copyWith(quotaWindows: []).limitingQuota(now), isNull);
  });

  test('hidden notifications stay hidden after an inbox refresh', () async {
    final s = NotificationService(null, backend: _Inbox());
    await s.bindOwner('A');
    await s.refreshInbox();
    expect(s.items, hasLength(1));
    s.clearAll();
    await s.refreshInbox();
    expect(s.items, isEmpty);
    await s.close();
  });
}
