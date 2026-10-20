String money(int? micros, {int decimals = 2}) => micros == null
    ? 'Chưa biết'
    : '${micros < 0 ? '−' : ''}\$${(micros.abs() / 1000000).toStringAsFixed(decimals)}';
String compactTokens(int? value) {
  if (value == null) return 'Chưa biết';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
  }
  return '$value';
}

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
String shortTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
int? parseUsd(String raw) {
  if (raw.trim().isEmpty) return null;
  final match = RegExp(r'^(\d{1,7})(?:[.,](\d{1,6}))?$').firstMatch(raw.trim());
  if (match == null) {
    throw const FormatException('Nhập USD hợp lệ, tối đa 6 số thập phân.');
  }
  return int.parse(match.group(1)!) * 1000000 +
      int.parse((match.group(2) ?? '').padRight(6, '0'));
}

String usdInput(int? micros) => micros == null
    ? ''
    : (micros / 1000000).toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
