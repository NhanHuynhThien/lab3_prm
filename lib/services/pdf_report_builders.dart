import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/ai_account.dart';
import '../models/usage_session.dart';
import '../utils/formatters.dart';
import 'reporting_calendar.dart';

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
                'Báo cáo chi phí và sử dụng AI',
                style: const pw.TextStyle(fontSize: 12, color: mutedText),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Kỳ: $periodLabel',
                style: pw.TextStyle(
                  fontSize: 11,
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

  static pw.Widget buildSummaryCards(
    int sessionCount,
    int? costMicros,
    int? tokenCount,
    int accountCount,
  ) {
    return pw.Row(
      children: [
        _buildMetricBox(
          'Tổng chi phí đã biết',
          money(costMicros),
          primaryColor,
        ),
        pw.SizedBox(width: 8),
        _buildMetricBox(
          'Tổng token đã ghi',
          compactTokens(tokenCount),
          darkText,
        ),
        pw.SizedBox(width: 8),
        _buildMetricBox('Số phiên công việc', '$sessionCount phiên', darkText),
        pw.SizedBox(width: 8),
        _buildMetricBox('Tài khoản AI', '$accountCount tài khoản', darkText),
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

  static pw.Widget buildAccountTable(
    List<AIAccount> accounts,
    List<UsageSession> sessions,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '1. Thống kê theo tài khoản AI',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: cardBorder, width: 0.5),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: mintBackground),
          headers: [
            'Tài khoản',
            'Nhà cung cấp',
            'Gói cước',
            'Số phiên',
            'Chi phí (USD)',
            'Token',
          ],
          data: accounts.map((acc) => accountRow(acc, sessions)).toList(),
        ),
      ],
    );
  }

  /// Sessions without any known figure stay "Chưa biết", never 0.
  static List<String> accountRow(AIAccount acc, List<UsageSession> sessions) {
    final rows = sessions.where((s) => s.accountId == acc.id).toList();
    int? total(Iterable<int?> values) {
      final known = values.whereType<int>();
      return rows.isNotEmpty && known.isEmpty
          ? null
          : known.fold<int>(0, (a, b) => a + b);
    }

    return [
      acc.alias,
      acc.provider,
      acc.plan.isEmpty ? 'Mặc định' : acc.plan,
      '${rows.length}',
      money(total(rows.map((s) => s.costMicros))),
      compactTokens(total(rows.map((s) => s.knownTokens))),
    ];
  }

  static pw.Widget buildPurposeTable(
    Map<String, int> counts,
    Map<String, int> costs,
  ) {
    if (counts.isEmpty) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '2. Phân bổ theo mục đích sử dụng',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: cardBorder, width: 0.5),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: mintBackground),
          headers: ['Mục đích', 'Số phiên', 'Chi phí (USD)'],
          data: counts.entries
              .map((e) => [e.key, '${e.value} phiên', money(costs[e.key])])
              .toList(),
        ),
      ],
    );
  }

  static pw.Widget buildRecentSessionsTable(
    List<UsageSession> sessions, [
    String timezone = 'device',
  ]) {
    final recent = sessions.take(10).toList();
    if (recent.isEmpty) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '3. Phiên sử dụng gần đây (tối đa 10 phiên)',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: cardBorder, width: 0.5),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: mintBackground),
          headers: ['Thời gian', 'Công việc', 'Mục đích', 'Chi phí', 'Token'],
          data: recent.map((s) {
            return [
              '${ReportingCalendar.dayKey(s.occurredAt, timezone)} ${shortTime(s.occurredAt, timezone: timezone)}',
              s.title,
              s.purpose.label,
              s.costMicros != null ? money(s.costMicros!) : 'Chưa rõ',
              s.knownTokens != null ? compactTokens(s.knownTokens!) : 'Chưa rõ',
            ];
          }).toList(),
        ),
      ],
    );
  }
}
