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
import 'pdf_report_sections.dart';
import 'report_summary.dart';

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
    final summary = ReportSummary.of(sessions, timezone: timezone);
    final n = summary.sessionCount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        header: (context) =>
            PdfReportBuilders.buildHeader(userEmail, periodLabel),
        footer: (context) => PdfReportBuilders.buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          PdfReportBuilders.buildSummaryCards(summary, accounts.length),
          pw.SizedBox(height: 12),
          pw.Text(
            '${['${summary.autoCount}/$n phiên do Companion ghi tự động từ log CLI', '${summary.knownTokenCount}/$n phiên có token', if (summary.hasCost) '${summary.knownCostCount}/$n phiên có chi phí'].join('; ')}. Số liệu thiếu không được tính là 0.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfReportBuilders.mutedText,
            ),
          ),
          ...PdfReportSections(summary, timezone).build(accounts),
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
