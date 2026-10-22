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
  int _epoch = 0, _sequence = 0;

  Stream<List<ExportReport>> get reportsStream => _reportsController.stream;
  List<ExportReport> get reports => List.unmodifiable(_reports);

  void bindOwner(String? uid) {
    if (_closed || uid == _ownerId) return;
    _epoch++;
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
    final owner = _requireOwner();
    final epoch = _epoch;
    final reportId =
        'rep_${DateTime.now().millisecondsSinceEpoch}_${_sequence++}';
    final fileName =
        'tokenledger_report_${DateTime.now().year}_${DateTime.now().month}_$reportId.pdf';

    final bytes = await pdfService.generateReportBytes(
      userEmail: userEmail,
      periodLabel: periodLabel,
      accounts: accounts,
      sessions: sessions,
    );
    _checkOwner(owner, epoch);
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
    _checkOwner(owner, epoch);

    final report = ExportReport(
      id: reportId,
      uid: owner,
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
    final owner = _requireOwner();
    final epoch = _epoch;
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index < 0) {
      throw StateError('Không tìm thấy báo cáo $reportId.');
    }
    final current = _reports[index];
    if (current.uid != owner) {
      throw StateError('Báo cáo không thuộc phiên hiện tại.');
    }
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
        uid: owner,
        fileName: current.fileName,
        bytes: bytes,
        onProgress: (value) {
          if (!_closed && epoch == _epoch && owner == _ownerId) {
            onProgress?.call(value);
          }
        },
      );
      _checkOwner(owner, epoch);

      final updated = _reports[index].copyWith(
        status: 'uploaded_cloud',
        storageUrl: downloadUrl,
      );
      _reports[index] = updated;
      _publish();

      unawaited(analyticsService.record(ProductEvent.uploadReport()));
      return updated;
    } catch (e) {
      if (_closed || epoch != _epoch || owner != _ownerId) rethrow;
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
    final owner = _requireOwner();
    final report = _reports.firstWhere((r) => r.id == reportId);
    if (report.uid != owner) {
      throw StateError('Báo cáo không thuộc phiên hiện tại.');
    }
    if (report.localPath != null) {
      await pdfService.openFile(report.localPath!);
    }
  }

  String _requireOwner() {
    if (_closed || _ownerId == null) {
      throw StateError('Đăng nhập để xử lý báo cáo.');
    }
    return _ownerId!;
  }

  void _checkOwner(String owner, int epoch) {
    if (_closed || owner != _ownerId || epoch != _epoch) {
      throw StateError('Phiên đăng nhập đã thay đổi. Hãy tạo lại báo cáo.');
    }
  }

  void _publish() {
    if (_closed) return;
    _reportsController.add(List.unmodifiable(_reports));
  }

  Future<void> close() async {
    _closed = true;
    _epoch++;
    _reports.clear();
    _cachedBytes.clear();
    await _reportsController.close();
  }
}
