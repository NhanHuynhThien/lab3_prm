import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/ai_account.dart';
import '../models/usage_session.dart';
import '../utils/formatters.dart';
import 'report_summary.dart';

class PdfReportBuilders {
  const PdfReportBuilders._();

  static const PdfColor primaryColor = PdfColor.fromInt(0xFF006C49);
  static const PdfColor mintBackground = PdfColor.fromInt(0xFFE8F7EF);
  static const PdfColor darkText = PdfColor.fromInt(0xFF1B1B1F);
  static const PdfColor mutedText = PdfColor.fromInt(0xFF535F5B);
  static const PdfColor cardBorder = PdfColor.fromInt(0xFFDEE5E0);

  static pw.Widget buildHeader(String? userEmail, String periodLabel) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: cardBorder, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TokenLedger',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.Text(
                'Báo cáo sử dụng AI',
                style: const pw.TextStyle(fontSize: 12, color: mutedText),
              ),
            ],
          ),
          pw.SizedBox(width: 24),
          // Long period labels wrap here instead of crowding the brand.
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Kỳ: $periodLabel',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (userEmail != null && userEmail.isNotEmpty)
                  pw.Text(
                    userEmail,
                    style: const pw.TextStyle(fontSize: 10, color: mutedText),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: cardBorder, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Báo cáo tự động từ TokenLedger • Bảo mật và minh bạch ngân sách AI',
            style: const pw.TextStyle(fontSize: 8, color: mutedText),
          ),
          pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: mutedText),
          ),
        ],
      ),
    );
  }

  /// Headline figures; cost appears only when some source reported one.
  static pw.Widget buildSummaryCards(ReportSummary summary, int accountCount) {
    final boxes = <pw.Widget>[
      _buildMetricBox(
        'Tổng token',
        compactTokens(summary.tokens),
        primaryColor,
      ),
      _buildMetricBox('Số phiên', '${summary.sessionCount} phiên', darkText),
      _buildMetricBox('Agent / tài khoản', '$accountCount', darkText),
      if (summary.hasCost)
        _buildMetricBox('Chi phí đã biết', money(summary.costMicros), darkText),
    ];
    return pw.Row(
      children: [
        for (var i = 0; i < boxes.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 8),
          boxes[i],
        ],
      ],
    );
  }

  static pw.Widget _buildMetricBox(
    String label,
    String value,
    PdfColor valColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: mintBackground,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: cardBorder, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: mutedText),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: valColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sessions without any known figure stay "Chưa biết", never 0.
  static List<String> accountRow(AIAccount acc, List<UsageSession> sessions) {
    final row = ReportSummary.of(sessions).account(acc);
    return [
      acc.alias,
      acc.provider,
      acc.plan.isEmpty ? 'Mặc định' : acc.plan,
      '${row.sessions}',
      money(row.costMicros),
      compactTokens(row.tokens),
    ];
  }
}
