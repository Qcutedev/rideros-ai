import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Display formatting. Money is formatted from the decimal digits, never through
/// `double`, so what the rider sees is exactly what the API returned.
abstract final class Formats {
  /// `1234.5` → `1,234.50`; `-80` → `-80.00`.
  static String money(Decimal value) {
    final fixed = value.abs().toStringAsFixed(2);
    final dot = fixed.indexOf('.');
    final integer = _group(fixed.substring(0, dot));
    final sign = value < Decimal.zero ? '-' : '';
    return '$sign$integer${fixed.substring(dot)}';
  }

  /// Whole count with thousands separators: `64701` → `64,701`.
  static String count(int value) =>
      value < 0 ? '-${_group('${-value}')}' : _group('$value');

  /// `฿1,234.50` for THB, otherwise `1,234.50 USD`.
  static String currency(Decimal value, String currency) =>
      currency == 'THB' ? '฿${money(value)}' : '${money(value)} $currency';

  /// Hours, distances: at most two decimals and no trailing zeros: `7.5`, `12`.
  static String compact(Decimal value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.contains('.')
        ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
        : fixed;
  }

  /// Plain decimal for an input field: `45.50` → `45.5`, `12.00` → `12`.
  static String decimalInput(Decimal value) {
    final text = value.toString();
    return text.contains('.') ? text.replaceFirst(RegExp(r'\.?0+$'), '') : text;
  }

  /// `10 พ.ย. 2026` (date-only values are UTC midnight; read as calendar dates).
  static String date(DateTime value, String locale) =>
      DateFormat.yMMMd(locale).format(_calendar(value));

  /// `10 พ.ย.`
  static String dayMonth(DateTime value, String locale) =>
      DateFormat.MMMd(locale).format(_calendar(value));

  /// `พ.ย.`
  static String monthShort(DateTime value, String locale) =>
      DateFormat.MMM(locale).format(_calendar(value));

  /// `พฤศจิกายน 2026`
  static String monthYear(DateTime value, String locale) =>
      DateFormat.yMMMM(locale).format(_calendar(value));

  /// `18:30` (24-hour, without the Thai "น." suffix of `DateFormat.Hm`).
  static String time(DateTime value, String locale) =>
      DateFormat('HH:mm', locale).format(value);

  static DateTime _calendar(DateTime v) => DateTime(v.year, v.month, v.day);

  static String _group(String digits) {
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}
