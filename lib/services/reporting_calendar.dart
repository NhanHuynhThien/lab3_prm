import 'package:timezone/data/latest.dart' as database;
import 'package:timezone/timezone.dart' as tz;

/// Calendar arithmetic stays here; views never derive financial boundaries.
/// `device` preserves the explicit legacy policy until the user changes it.
abstract final class ReportingCalendar {
  static final _locations = (() {
    database.initializeTimeZones();
    return tz.timeZoneDatabase.locations;
  })();

  /// Drop TZDateTime's overridden toLocal() at model boundaries.
  static DateTime instantUtc(DateTime value) =>
      DateTime.fromMicrosecondsSinceEpoch(
        value.microsecondsSinceEpoch,
        isUtc: true,
      );

  static void validateZone(String zone) {
    if (zone != 'device' && zone != 'UTC' && !_locations.containsKey(zone)) {
      throw ArgumentError(
        'Múi giờ IANA không hợp lệ. Ví dụ: Asia/Ho_Chi_Minh.',
      );
    }
  }

  static DateTime at(DateTime instant, String zone) {
    validateZone(zone);
    return zone == 'device'
        ? DateTime.fromMicrosecondsSinceEpoch(instant.microsecondsSinceEpoch)
        : tz.TZDateTime.from(
            instant,
            zone == 'UTC' ? tz.UTC : _locations[zone]!,
          );
  }

  static DateTime wall(
    String zone,
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
  ]) {
    validateZone(zone);
    return zone == 'device'
        ? DateTime(year, month, day, hour, minute)
        : tz.TZDateTime(
            zone == 'UTC' ? tz.UTC : _locations[zone]!,
            year,
            month,
            day,
            hour,
            minute,
          );
  }

  /// Days 29–31 clamp to the last actual day of each month, independently.
  static ({DateTime start, DateTime end}) cycle(
    DateTime now,
    String zone,
    int startDay,
  ) {
    if (startDay < 1 || startDay > 31) {
      throw ArgumentError('Ngày kỳ không hợp lệ.');
    }
    final local = at(now, zone);
    DateTime boundary(int month) {
      final first = DateTime.utc(local.year, month);
      final last = DateTime.utc(first.year, first.month + 1, 0).day;
      return wall(
        zone,
        first.year,
        first.month,
        startDay > last ? last : startDay,
      );
    }

    final month = now.isBefore(boundary(local.month))
        ? local.month - 1
        : local.month;
    return (start: boundary(month).toUtc(), end: boundary(month + 1).toUtc());
  }

  static String dayKey(DateTime instant, String zone) {
    final d = at(instant, zone);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String zoneLabel(String zone) =>
      zone == 'device' ? 'Múi giờ thiết bị (dữ liệu cũ)' : zone;
}
