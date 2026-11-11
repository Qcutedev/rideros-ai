import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

/// Money and other decimals travel as JSON strings (`"800.00"`, AD-6). Never `double`.
class DecimalConverter implements JsonConverter<Decimal, Object> {
  const DecimalConverter();

  @override
  Decimal fromJson(Object json) => _parse(json);

  @override
  Object toJson(Decimal value) => value.toString();
}

class NullableDecimalConverter implements JsonConverter<Decimal?, Object?> {
  const NullableDecimalConverter();

  @override
  Decimal? fromJson(Object? json) => json == null ? null : _parse(json);

  @override
  Object? toJson(Decimal? value) => value?.toString();
}

Decimal _parse(Object json) {
  if (json is String) return Decimal.parse(json);
  if (json is int) return Decimal.fromInt(json);
  throw FormatException('Expected a decimal string, got ${json.runtimeType}');
}
