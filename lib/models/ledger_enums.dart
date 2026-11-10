DateTime decodeTimestamp(Object? value) {
  if (value is! String) {
    throw const FormatException('Timestamp phải là chuỗi ISO.');
  }
  final parts = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?(Z|[+-]\d{2}:\d{2})?$',
  ).firstMatch(value);
  if (parts == null) throw const FormatException('Timestamp ISO không hợp lệ.');
  final numbers = List.generate(6, (i) => int.parse(parts.group(i + 1)!));
  final date = DateTime.utc(
    numbers[0],
    numbers[1],
    numbers[2],
    numbers[3],
    numbers[4],
    numbers[5],
  );
  if (date.year != numbers[0] ||
      date.month != numbers[1] ||
      date.day != numbers[2] ||
      date.hour != numbers[3] ||
      date.minute != numbers[4] ||
      date.second != numbers[5]) {
    throw const FormatException('Ngày hoặc giờ không tồn tại.');
  }
  final zone = parts.group(7);
  if (zone != null &&
      zone != 'Z' &&
      (int.parse(zone.substring(1, 3)) > 23 ||
          int.parse(zone.substring(4)) > 59)) {
    throw const FormatException('UTC offset không hợp lệ.');
  }
  return DateTime.parse(value);
}

enum Purpose {
  code('Lập trình'),
  debug('Sửa lỗi'),
  review('Code review'),
  test('Kiểm thử'),
  learn('Học tập'),
  write('Viết nội dung'),
  research('Nghiên cứu'),
  design('Thiết kế'),
  other('Khác');

  const Purpose(this.label);
  final String label;
}

enum BillingMode {
  subscription('Thuê bao'),
  api('API theo sử dụng'),
  other('Khác');

  const BillingMode(this.label);
  final String label;
}

enum DataSource {
  manual('Nhập tay'),

  /// Read automatically from local CLI logs by the desktop Companion.
  companion('Tự động từ Companion'),
  demo('Demo giả định'),
  legacy('Dữ liệu cũ chưa phân loại');

  const DataSource(this.label);
  final String label;
}

enum CostBasis {
  manual('Chi phí nhập tay'),
  actual('Chi phí thực đã xác nhận'),
  unspecified('Chưa xác nhận loại chi phí'),
  unknown('Chưa biết');

  const CostBasis(this.label);
  final String label;
}
