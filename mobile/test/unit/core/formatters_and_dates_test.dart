import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rideros_ai/core/utils/date_json.dart';
import 'package:rideros_ai/core/utils/formatters.dart';

Decimal d(String v) => Decimal.parse(v);

void main() {
  setUpAll(() => initializeDateFormatting('th'));

  group('Formats.money (exact decimals, never double)', () {
    for (final (input, expected) in [
      ('0', '0.00'),
      ('5', '5.00'),
      ('800.5', '800.50'),
      ('1234.56', '1,234.56'),
      ('1000000', '1,000,000.00'),
      ('-80', '-80.00'),
      ('-1234.5', '-1,234.50'),
      ('9999999999.99', '9,999,999,999.99'),
      ('0.1', '0.10'),
    ]) {
      test(
        '$input → $expected',
        () => expect(Formats.money(d(input)), expected),
      );
    }
  });

  test('Formats.currency puts ฿ before THB and the code after others', () {
    expect(Formats.currency(d('1200'), 'THB'), '฿1,200.00');
    expect(Formats.currency(d('-3.5'), 'THB'), '฿-3.50');
    expect(Formats.currency(d('12'), 'USD'), '12.00 USD');
  });

  test('Formats.compact drops trailing zeros', () {
    expect(Formats.compact(d('7.50')), '7.5');
    expect(Formats.compact(d('12.00')), '12');
    expect(Formats.compact(d('10')), '10');
    expect(Formats.compact(d('0.25')), '0.25');
    expect(Formats.compact(d('100.10')), '100.1');
  });

  test('Formats.decimalInput gives a value the validators accept', () {
    expect(Formats.decimalInput(d('45.50')), '45.5');
    expect(Formats.decimalInput(d('120')), '120');
    expect(Formats.decimalInput(d('0.0125')), '0.0125');
  });

  test('Thai date formats', () {
    final day = DateTime.utc(2026, 11, 10);
    expect(Formats.date(day, 'th'), contains('2026'));
    expect(Formats.date(day, 'th'), contains('พ.ย.'));
    expect(Formats.monthYear(day, 'th'), contains('พฤศจิกายน'));
    expect(Formats.time(DateTime(2026, 11, 10, 18, 5), 'th'), '18:05');
  });

  group('date_json', () {
    test('ISO dates round-trip as UTC midnight', () {
      final date = parseIsoDate('2026-02-03');
      expect(date, DateTime.utc(2026, 2, 3));
      expect(formatIsoDate(date), '2026-02-03');
      expect(formatIsoDate(DateTime.utc(999, 1, 1)), '0999-01-01');
      expect(() => parseIsoDate('2026-02'), throwsFormatException);
    });

    test('dateOnly drops the time and keeps the calendar date', () {
      expect(
        dateOnly(DateTime(2026, 11, 10, 23, 59)),
        DateTime.utc(2026, 11, 10),
      );
    });

    test('aware datetimes carry an offset (UTC → Z)', () {
      expect(
        formatAwareDateTime(DateTime.utc(2026, 11, 10, 11, 0, 5)),
        '2026-11-10T11:00:05Z',
      );
      final local = DateTime(2026, 11, 10, 18, 30);
      final text = formatAwareDateTime(local);
      expect(text, startsWith('2026-11-10T18:30:00'));
      expect(text, matches(RegExp(r'[+-]\d\d:\d\d$')));
      // The offset makes the instant unambiguous.
      expect(DateTime.parse(text).toUtc(), local.toUtc());
    });

    test('AwareDateTimeConverter reads any offset into local time', () {
      const converter = AwareDateTimeConverter();
      final parsed = converter.fromJson('2026-11-10T11:00:00+00:00');
      expect(parsed.isUtc, isFalse);
      expect(parsed.toUtc(), DateTime.utc(2026, 11, 10, 11));
    });
  });
}
