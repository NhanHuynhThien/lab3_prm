import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ai_account.dart';
import 'package:token_ledger/models/usage_session.dart';
import 'package:token_ledger/services/analytics_service.dart';
import 'package:token_ledger/services/pdf_report_service.dart';
import 'package:token_ledger/services/report_management_service.dart';
import 'package:token_ledger/services/storage_service.dart';

class _Pdf extends PdfReportService {
  Completer<Uint8List>? gate;
  @override
  Future<Uint8List> generateReportBytes({
    required String? userEmail,
    required String periodLabel,
    required List<AIAccount> accounts,
    required List<UsageSession> sessions,
  }) async => gate == null ? Uint8List.fromList([1, 2, 3]) : gate!.future;
  @override
  Future<String?> savePdfLocally({
    required String fileName,
    required Uint8List bytes,
  }) async => null;
}

class _Storage implements StorageTransport {
  Completer<String>? gate;
  String? owner;
  @override
  Future<String> uploadReport({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double)? onProgress,
  }) async {
    owner = uid;
    return gate?.future ?? 'https://example.test/report.pdf';
  }

  @override
  Future<void> deleteReport({
    required String uid,
    required String fileName,
  }) async {}
}

void main() {
  late _Pdf pdf;
  late _Storage storage;
  late AnalyticsService analytics;
  late ReportManagementService manager;
  setUp(() {
    pdf = _Pdf();
    storage = _Storage();
    analytics = AnalyticsService(null);
    manager = ReportManagementService(
      pdfService: pdf,
      storageService: StorageService(storage),
      analyticsService: analytics,
    )..bindOwner('A');
  });
  tearDown(() async {
    await manager.close();
    await analytics.close();
  });
  Future<dynamic> generate() => manager.generateReport(
    periodLabel: 'QA',
    accounts: [],
    sessions: [],
    userEmail: null,
  );
  test(
    'generation completing after UID change cannot publish A PDF into B',
    () async {
      pdf.gate = Completer<Uint8List>();
      final pending = generate();
      final assertion = expectLater(pending, throwsStateError);
      manager.bindOwner('B');
      pdf.gate!.complete(Uint8List.fromList([1]));
      await assertion;
      expect(manager.reports, isEmpty);
    },
  );
  test('upload finishing after logout retains captured owner and cannot index cleared reports', () async {
    final report = await generate();
    storage.gate = Completer<String>();
    final pending = manager.uploadToCloudStorage(reportId: report.id);
    final assertion = expectLater(pending, throwsStateError);
    expect(storage.owner, 'A');
    manager.bindOwner(null);
    storage.gate!.complete('https://example.test/old-owner.pdf');
    await assertion;
    expect(manager.reports, isEmpty);
  });
  test(
    'signed-out generation rejected and same owner binding preserves reports',
    () async {
      await generate();
      manager.bindOwner('A');
      expect(manager.reports, hasLength(1));
      manager.bindOwner(null);
      await expectLater(generate(), throwsStateError);
    },
  );
}
