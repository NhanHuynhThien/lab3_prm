import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/gemini_activity_summary.dart';

/// Google Takeout My Activity JSON. No token count is inferred from chat length.
GeminiActivitySummary parseGeminiActivityFile(
  ({Uint8List bytes, DateTime now}) request,
) {
  if (request.bytes.length > 8 * 1024 * 1024) {
    throw const FormatException(
      'File vượt 8 MB. Hãy xuất riêng hoạt động Gemini.',
    );
  }
  dynamic document;
  try {
    document = jsonDecode(utf8.decode(request.bytes));
  } catch (_) {
    throw const FormatException(
      'Chọn file JSON từ Google Takeout, không phải file ZIP.',
    );
  }
  final rows = document is List
      ? document
      : document is Map
      ? document['activities']
      : null;
  if (rows is! List || rows.length > 100000) {
    throw const FormatException(
      'File chưa đúng định dạng My Activity của Google.',
    );
  }
  final now = request.now.toUtc();
  final start = now.subtract(const Duration(days: 30));
  final daily = <String, int>{};
  final seen = <String>{};
  var validDates = 0;
  for (final raw in rows) {
    if (raw is! Map) continue;
    final products = raw['products'];
    final labels = <String>[
      if (raw['header'] is String) raw['header'] as String,
      if (products is List) ...products.whereType<String>(),
    ];
    if (!labels.any(
      (s) => RegExp(r'gemini|\bbard\b', caseSensitive: false).hasMatch(s),
    )) {
      continue;
    }
    final time = raw['time'];
    if (time is! String || !RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(time)) {
      continue;
    }
    final date = DateTime.tryParse(time)?.toUtc();
    if (date == null) continue;
    validDates++;
    if (date.isBefore(start) || date.isAfter(now)) continue;
    // Deduplicate identical activity records; the digest stays in this worker.
    final key = sha256
        .convert(utf8.encode('$time\n${raw['title']}\n${raw['titleUrl']}'))
        .toString();
    if (!seen.add(key)) continue;
    final day = date.toIso8601String().substring(0, 10);
    daily.update(day, (n) => n + 1, ifAbsent: () => 1);
  }
  if (validDates == 0) {
    throw const FormatException(
      'Không tìm thấy hoạt động Gemini có thời điểm hợp lệ. Trong Takeout, chọn My Activity → Gemini Apps → JSON.',
    );
  }
  return GeminiActivitySummary(
    importedAt: now,
    periodStart: start,
    dailyCounts: daily,
  );
}
