import 'package:json_annotation/json_annotation.dart';

/// A calendar date without time or zone, e.g. `occurred_on`. Kept as a UTC midnight
/// `DateTime` so arithmetic never crosses a daylight-saving change.
DateTime dateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

String formatIsoDate(DateTime value) =>
    '${_pad(value.year, 4)}-${_pad(value.month)}-${_pad(value.day)}';

/// Parses `YYYY-MM-DD`.
DateTime parseIsoDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) throw FormatException('Not a date: $value');
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// ISO 8601 with the numeric offset of [value]'s zone, e.g. `2026-11-10T18:00:00+07:00`.
/// The backend only accepts aware datetimes; `DateTime.toIso8601String()` drops the
/// offset of a local time.
String formatAwareDateTime(DateTime value) {
  if (value.isUtc) {
    return '${formatIsoDate(value)}T${_time(value)}Z';
  }
  final offset = value.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  return '${formatIsoDate(value)}T${_time(value)}'
      '$sign${_pad(minutes ~/ 60)}:${_pad(minutes % 60)}';
}

String _time(DateTime v) =>
    '${_pad(v.hour)}:${_pad(v.minute)}:${_pad(v.second)}';

String _pad(int value, [int width = 2]) => value.toString().padLeft(width, '0');

class DateOnlyConverter implements JsonConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromJson(String json) => parseIsoDate(json);

  @override
  String toJson(DateTime value) => formatIsoDate(value);
}

/// Reads any ISO datetime into local time; writes it with its offset.
class AwareDateTimeConverter implements JsonConverter<DateTime, String> {
  const AwareDateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toLocal();

  @override
  String toJson(DateTime value) => formatAwareDateTime(value);
}
