import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_account.dart';
import '../models/export_report.dart';
import '../models/usage_session.dart';
import 'analytics_service.dart';
import 'pdf_report_service.dart';
import 'storage_service.dart';

class ReportManagementService {
  ReportManagementService({
    required this.pdfService,
    required this.storageService,
    required this.analyticsService,
  });

  final PdfReportService pdfService;
  final StorageService storageService;
  final AnalyticsService analyticsService;

  final _reportsController = StreamController<List<ExportReport>>.broadcast(
    sync: true,
  );
  final List<ExportReport> _reports = [];
  final Map<String, Uint8List> _cachedBytes = {};
  String? _ownerId;
  bool _closed = false;

  Stream<List<ExportReport>> get reportsStream => _reportsController.stream;
  List<ExportReport> get reports => List.unmodifiable(_reports);

  void bindOwner(String? uid) {
    if (_closed) return;
    _ownerId = uid;
    _reports.clear();
    _cachedBytes.clear();
    _publish();
  }

  Future<ExportReport> generateReport({
    required String periodLabel,
    required List<AIAccount> accounts,
    required List<UsageSession> sessions,
    required String? userEmail,
  }) async {
    final reportId = 'rep_${DateTime.now().millisecondsSinceEpoch}';
    final fileName =
        'tokenledger_report_${DateTime.now().year}_${DateTime.now().month}_$reportId.pdf';

    final bytes = await pdfService.generateReportBytes(
      userEmail: userEmail,
      periodLabel: periodLabel,
      accounts: accounts,
      sessions: sessions,
    );
    _cachedBytes[reportId] = bytes;

    String? localPath;
    try {
      localPath = await pdfService.savePdfLocally(
        fileName: fileName,
        bytes: bytes,
      );
    } catch (_) {
      // Best-effort for local storage
    }

    final report = ExportReport(
      id: reportId,
      uid: _ownerId ?? 'local',
      fileName: fileName,
      periodLabel: periodLabel,
      generatedAt: DateTime.now(),
      fileSizeBytes: bytes.lengthInBytes,
      localPath: localPath,
      status: 'ready_local',
    );

    _reports.insert(0, report);
    _publish();

    unawaited(analyticsService.record(ProductEvent.exportReport()));

    return report;
  }

  Future<ExportReport> uploadToCloudStorage({
    required String reportId,
    void Function(double progress)? onProgress,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index < 0) {
      throw StateError('Không tìm thấy báo cáo $reportId.');
    }
    final current = _reports[index];
    final bytes = _cachedBytes[reportId];
    if (bytes == null) {
      throw StateError(
        'Dữ liệu PDF không còn trong bộ nhớ đệm; hãy tạo lại báo cáo.',
      );
    }

    _reports[index] = current.copyWith(status: 'uploading', errorMessage: null);
    _publish();

    try {
      final downloadUrl = await storageService.uploadReport(
        uid: _ownerId ?? 'anonymous',
        fileName: current.fileName,
        bytes: bytes,
        onProgress: onProgress,
      );

      final updated = _reports[index].copyWith(
        status: 'uploaded_cloud',
        storageUrl: downloadUrl,
      );
      _reports[index] = updated;
      _publish();

      unawaited(analyticsService.record(ProductEvent.uploadReport()));
      return updated;
    } catch (e) {
      final failed = _reports[index].copyWith(
        status: 'failed',
        errorMessage: 'Lỗi tải lên Cloud Storage: ${e.toString()}',
      );
      _reports[index] = failed;
      _publish();
      rethrow;
    }
  }

  Future<void> openLocalReport(String reportId) async {
    final report = _reports.firstWhere((r) => r.id == reportId);
    if (report.localPath != null) {
      await pdfService.openFile(report.localPath!);
    }
  }

  void _publish() {
    if (_closed) return;
    _reportsController.add(List.unmodifiable(_reports));
  }

  Future<void> close() async {
    _closed = true;
    await _reportsController.close();
  }
}
