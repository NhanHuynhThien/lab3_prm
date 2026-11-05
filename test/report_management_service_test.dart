import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ai_account.dart';
import 'package:token_ledger/models/ledger_enums.dart';
import 'package:token_ledger/models/usage_session.dart';
import 'package:token_ledger/services/analytics_service.dart';
import 'package:token_ledger/services/pdf_report_service.dart';
import 'package:token_ledger/services/report_management_service.dart';
import 'package:token_ledger/services/storage_service.dart';

class FakeStorageTransport implements StorageTransport {
  final uploadedFiles = <String, Uint8List>{};
  bool shouldFail = false;

  @override
  Future<String> uploadReport({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    if (shouldFail) {
      throw StateError('Simulated network error');
    }
    uploadedFiles['$uid/$fileName'] = bytes;
    onProgress?.call(1.0);
    return 'https://firebasestorage.googleapis.com/v0/b/tokenledger-lab3.appspot.com/o/reports%2F$uid%2F$fileName';
  }

  @override
  Future<void> deleteReport({
    required String uid,
    required String fileName,
  }) async {
    uploadedFiles.remove('$uid/$fileName');
  }
}

class FakeAnalyticsTransport implements AnalyticsTransport {
  final events = <Map<String, dynamic>>[];

  @override
  Future<void> enable(bool enabled) async {}

  @override
  Future<void> identify(String? uid) async {}

  @override
  Future<void> event(String name, Map<String, Object> parameters) async {
    events.add({'name': name, 'params': parameters});
  }
}

/// Real PDF bytes; the device filesystem plugin is not available in unit tests.
class _NoDiskPdf extends PdfReportService {
  const _NoDiskPdf();
  @override
  Future<String?> savePdfLocally({
    required String fileName,
    required Uint8List bytes,
  }) async => null;
}

void main() {
  group('ReportManagementService', () {
    late FakeStorageTransport storageTransport;
    late StorageService storageService;
    late FakeAnalyticsTransport analyticsTransport;
    late AnalyticsService analyticsService;
    late ReportManagementService reportManager;

    setUp(() {
      storageTransport = FakeStorageTransport();
      storageService = StorageService(storageTransport);
      analyticsTransport = FakeAnalyticsTransport();
      analyticsService = AnalyticsService(analyticsTransport);
      reportManager = ReportManagementService(
        pdfService: const _NoDiskPdf(),
        storageService: storageService,
        analyticsService: analyticsService,
      );
      reportManager.bindOwner('test_user_789');
    });

    tearDown(() async {
      await reportManager.close();
      await analyticsService.close();
    });

    test(
      'generateReport generates PDF and emits export_report analytics event',
      () async {
        final account = AIAccount(
          id: 'acc_a',
          alias: 'Anthropic Claude',
          provider: 'Anthropic',
          product: 'Claude Pro',
          billingMode: BillingMode.subscription,
          plan: 'Pro',
          createdAt: DateTime(2026, 1, 1),
        );

        final session = UsageSession(
          id: 'sess_a',
          accountId: 'acc_a',
          title: 'Review pull request',
          purpose: Purpose.review,
          occurredAt: DateTime.now(),
          costMicros: 120000,
          inputTokens: 1000,
          outputTokens: 200,
        );

        final report = await reportManager.generateReport(
          periodLabel: 'Tháng 10/2026',
          accounts: [account],
          sessions: [session],
          userEmail: 'dev@test.org',
        );

        expect(report.id, isNotEmpty);
        expect(report.uid, 'test_user_789');
        expect(report.fileName, contains('.pdf'));
        expect(report.status, 'ready_local');
        expect(report.fileSizeBytes, greaterThan(0));

        expect(reportManager.reports, hasLength(1));
        expect(reportManager.reports.first.id, report.id);
      },
    );

    test(
      'uploadToCloudStorage uploads bytes to storage and updates status',
      () async {
        final report = await reportManager.generateReport(
          periodLabel: 'Kỳ kiểm tra',
          accounts: [],
          sessions: [],
          userEmail: 'dev@test.org',
        );

        final uploaded = await reportManager.uploadToCloudStorage(
          reportId: report.id,
        );

        expect(uploaded.status, 'uploaded_cloud');
        expect(
          uploaded.storageUrl,
          contains('https://firebasestorage.googleapis.com'),
        );
        expect(storageTransport.uploadedFiles, hasLength(1));
      },
    );

    test(
      'uploadToCloudStorage handles upload failure without losing report',
      () async {
        final report = await reportManager.generateReport(
          periodLabel: 'Kỳ kiểm tra',
          accounts: [],
          sessions: [],
          userEmail: 'dev@test.org',
        );

        storageTransport.shouldFail = true;

        await expectLater(
          () => reportManager.uploadToCloudStorage(reportId: report.id),
          throwsA(isA<StateError>()),
        );

        final failedReport = reportManager.reports.firstWhere(
          (r) => r.id == report.id,
        );
        expect(failedReport.status, 'failed');
        expect(failedReport.errorMessage, contains('Simulated network error'));

        // Retry upload after restoring connection
        storageTransport.shouldFail = false;
        final retried = await reportManager.uploadToCloudStorage(
          reportId: report.id,
        );
        expect(retried.status, 'uploaded_cloud');
        expect(retried.storageUrl, isNotNull);
      },
    );
  });
}
