import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/ai_account.dart';
import '../models/usage_session.dart';
import 'pdf_report_builders.dart';

class PdfReportService {
  const PdfReportService();

  Future<pw.Font> _resolveFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
      return pw.Font.ttf(fontData);
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  Future<Uint8List> generateReportBytes({
    required String? userEmail,
    required String periodLabel,
    required List<AIAccount> accounts,
    required List<UsageSession> sessions,
    String timezone = 'device',
  }) async {
    final pdf = pw.Document();
    final font = await _resolveFont();
    final boldFont = font;

    int totalCostMicros = 0;
    int totalTokens = 0;
    for (final s in sessions) {
      if (s.costMicros != null) totalCostMicros += s.costMicros!;
      if (s.knownTokens != null) totalTokens += s.knownTokens!;
    }

    final purposeCounts = <String, int>{};
    final purposeCost = <String, int>{};
    for (final s in sessions) {
      final pName = s.purpose.label;
      purposeCounts[pName] = (purposeCounts[pName] ?? 0) + 1;
      if (s.costMicros != null) {
        purposeCost[pName] = (purposeCost[pName] ?? 0) + s.costMicros!;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (context) =>
            PdfReportBuilders.buildHeader(userEmail, periodLabel),
        footer: (context) => PdfReportBuilders.buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          PdfReportBuilders.buildSummaryCards(
            sessions.length,
            sessions.any((s) => s.costMicros != null) ? totalCostMicros : null,
            sessions.any((s) => s.knownTokens != null) ? totalTokens : null,
            accounts.length,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Sổ ghi nhận: ${sessions.where((s) => s.costMicros != null).length}/${sessions.length} phiên có chi phí; ${sessions.where((s) => s.knownTokens != null).length}/${sessions.length} có token. Số liệu thiếu không được xem là 0. Không bao gồm snapshot CLI/nguồn AI.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 24),
          PdfReportBuilders.buildAccountTable(accounts, sessions),
          pw.SizedBox(height: 24),
          PdfReportBuilders.buildPurposeTable(purposeCounts, purposeCost),
          pw.SizedBox(height: 24),
          PdfReportBuilders.buildRecentSessionsTable(sessions, timezone),
        ],
      ),
    );

    return pdf.save();
  }

  Future<String?> savePdfLocally({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) {
      return null;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<OpenResult?> openFile(String filePath) async {
    if (kIsWeb) return null;
    return OpenFilex.open(filePath);
  }
}
