import '../services/reporting_calendar.dart';

String preciseMoney(int? micros) =>
    money(micros, decimals: micros != null && micros % 10000 != 0 ? 6 : 2);

String money(int? micros, {int decimals = 2}) {
  if (micros == null) return 'Chưa biết';
  RangeError.checkValueInInterval(decimals, 0, 6, 'decimals');
  const powers = [1, 10, 100, 1000, 10000, 100000, 1000000];
  final divisor = powers[6 - decimals];
  final rounded = (micros.abs() + divisor ~/ 2) ~/ divisor;
  final whole = rounded ~/ powers[decimals];
  final fraction = decimals == 0
      ? ''
      : '.${(rounded % powers[decimals]).toString().padLeft(decimals, '0')}';
  return '${micros < 0 ? '−' : ''}\$$whole$fraction';
}

String compactTokens(int? value) {
  if (value == null) return 'Chưa biết';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
  }
  return '$value';
}

String shortDate(DateTime date, {String timezone = 'device'}) {
  final local = ReportingCalendar.at(date, timezone);
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}

String shortTime(DateTime date, {String timezone = 'device'}) {
  final local = ReportingCalendar.at(date, timezone);
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

int? parseUsd(String raw) {
  if (raw.trim().isEmpty) return null;
  final match = RegExp(r'^(\d{1,7})(?:[.,](\d{1,6}))?$').firstMatch(raw.trim());
  if (match == null) {
    throw const FormatException('Nhập USD hợp lệ, tối đa 6 số thập phân.');
  }
  return int.parse(match.group(1)!) * 1000000 +
      int.parse((match.group(2) ?? '').padRight(6, '0'));
}

String usdInput(int? micros) {
  if (micros == null) return '';
  final whole = micros.abs() ~/ 1000000;
  final fraction = (micros.abs() % 1000000)
      .toString()
      .padLeft(6, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '${micros < 0 ? '-' : ''}$whole${fraction.isEmpty ? '' : '.$fraction'}';
}

String exactTokens(int? value) => value == null
    ? 'Chưa có số liệu'
    : value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
String fullDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String elapsedLabel(int? seconds) {
  if (seconds == null) return 'Chưa có số liệu';
  final days = seconds ~/ 86400, hours = seconds % 86400 ~/ 3600;
  final minutes = seconds % 3600 ~/ 60, rest = seconds % 60;
  return [
    if (days > 0) '$days ngày',
    if (hours > 0) '$hours giờ',
    if (minutes > 0) '$minutes phút',
    if (rest > 0 || seconds == 0) '$rest giây',
  ].join(' ');
}
