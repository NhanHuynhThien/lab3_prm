import 'package:pdf/widgets.dart' as pw;

import '../models/ai_account.dart';
import '../utils/formatters.dart';
import 'pdf_report_builders.dart';
import 'report_summary.dart';
import 'reporting_calendar.dart';

/// Numbered tables of the PDF body. Every figure comes from [ReportSummary];
/// cost columns appear only when some session in the period has a cost.
class PdfReportSections {
  PdfReportSections(this.summary, this.timezone);

  final ReportSummary summary;
  final String timezone;
  int _number = 0;

  static const maxDays = 31, maxModels = 10, maxSessions = 15;

  /// Short tables move to the next page together with their heading; longer
  /// ones sit at the top level so MultiPage can split them across pages.
  static const maxInseparableRows = 20;

  List<pw.Widget> build(List<AIAccount> accounts) => [
    ..._accounts(accounts),
    ..._quotas(accounts),
    ..._grouped('Token theo ngày', 'Ngày', _lastDays(), note: _daysNote()),
    ..._grouped(
      'Theo model',
      'Model',
      summary.byModel.take(maxModels).toList(),
    ),
    ..._grouped('Theo mục đích sử dụng', 'Mục đích', summary.byPurpose),
    ..._recent(),
  ];

  List<pw.Widget> _accounts(List<AIAccount> accounts) {
    final cost = summary.hasCost;
    return _section(
      'Theo agent / tài khoản',
      [
        'Tài khoản',
        'Nhà cung cấp',
        'Gói',
        'Số phiên',
        'Token',
        if (cost) 'Chi phí (USD)',
      ],
      [
        for (final a in accounts)
          if (summary.account(a) case final row)
            [
              a.alias,
              a.provider,
              a.plan.isEmpty ? 'Mặc định' : a.plan,
              '${row.sessions}',
              compactTokens(row.tokens),
              if (cost) money(row.costMicros),
            ],
      ],
      empty: 'Không có tài khoản trong kỳ.',
    );
  }

  /// Quota is a snapshot taken when the source last reported, not a sum over
  /// the period; say so instead of mixing it with period totals.
  List<pw.Widget> _quotas(List<AIAccount> accounts) {
    final rows = [
      for (final a in accounts)
        for (final q in a.quotaWindows)
          [
            a.alias,
            q.window,
            'Đã dùng ${q.usedPercent}% · còn ${q.remainingPercent}%',
            _stamp(q.resetAt),
            _stamp(q.observedAt),
          ],
    ];
    if (rows.isEmpty) return const [];
    return _section(
      'Hạn mức hiện tại',
      ['Tài khoản', 'Cửa sổ', 'Mức dùng', 'Đặt lại', 'Ghi nhận lúc'],
      rows,
      note: 'Ảnh chụp tại thời điểm nguồn báo về, không cộng dồn theo kỳ.',
    );
  }

  List<ReportRow> _lastDays() {
    final days = summary.byDay;
    return days.length <= maxDays ? days : days.sublist(days.length - maxDays);
  }

  String? _daysNote() => summary.byDay.length > maxDays
      ? 'Hiển thị $maxDays ngày gần nhất có phiên trong kỳ.'
      : null;

  List<pw.Widget> _grouped(
    String title,
    String label,
    List<ReportRow> rows, {
    String? note,
  }) {
    if (rows.isEmpty) return const [];
    final cost = summary.hasCost;
    return _section(
      title,
      [label, 'Số phiên', 'Token', if (cost) 'Chi phí (USD)'],
      [
        for (final r in rows)
          [
            r.label,
            '${r.sessions}',
            compactTokens(r.tokens),
            if (cost) money(r.costMicros),
          ],
      ],
      note: note,
    );
  }

  List<pw.Widget> _recent() {
    final recent = summary.sessions.take(maxSessions).toList();
    if (recent.isEmpty) return const [];
    final cost = summary.hasCost;
    return _section(
      'Phiên gần đây (tối đa $maxSessions)',
      [
        'Thời gian',
        'Công việc',
        'Model',
        'Mục đích',
        'Token',
        if (cost) 'Chi phí',
      ],
      [
        for (final s in recent)
          [
            _stamp(s.occurredAt),
            s.title,
            s.modelId ?? '—',
            s.purpose.label,
            compactTokens(s.knownTokens),
            if (cost) money(s.costMicros),
          ],
      ],
      fontSize: 8,
    );
  }

  String _stamp(DateTime at) =>
      '${ReportingCalendar.dayKey(at, timezone)} ${shortTime(at, timezone: timezone)}';

  List<pw.Widget> _section(
    String title,
    List<String> headers,
    List<List<String>> rows, {
    String? note,
    String? empty,
    double fontSize = 9,
  }) {
    _number++;
    final heading = pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$_number. $title',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfReportBuilders.primaryColor,
            ),
          ),
          if (note != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                note,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfReportBuilders.mutedText,
                ),
              ),
            ),
        ],
      ),
    );
    final body = rows.isEmpty && empty != null
        ? pw.Text(empty, style: const pw.TextStyle(fontSize: 9))
        : pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(
              color: PdfReportBuilders.cardBorder,
              width: 0.5,
            ),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: fontSize,
            ),
            cellStyle: pw.TextStyle(fontSize: fontSize),
            headerDecoration: const pw.BoxDecoration(
              color: PdfReportBuilders.mintBackground,
            ),
            headers: headers,
            data: rows,
          );
    if (rows.length > maxInseparableRows) return [heading, body];
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [heading, body],
        ),
      ),
    ];
  }
}
