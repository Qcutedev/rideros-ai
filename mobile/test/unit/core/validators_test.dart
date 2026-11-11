import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/utils/validators.dart';
import 'package:rideros_ai/l10n/app_localizations_th.dart';

void main() {
  final l10n = AppLocalizationsTh();
  final v = Validators(l10n);

  group('email', () {
    test('accepts a normal address, also with surrounding spaces', () {
      expect(v.email('rider@example.com'), isNull);
      expect(v.email('  rider@example.co.th '), isNull);
    });

    test('rejects empty, malformed and too long', () {
      expect(v.email(''), l10n.validationRequired);
      expect(v.email(null), l10n.validationRequired);
      expect(v.email('rider'), l10n.validationEmailInvalid);
      expect(v.email('rider@example'), l10n.validationEmailInvalid);
      expect(v.email('a b@example.com'), l10n.validationEmailInvalid);
      expect(v.email('${'a' * 250}@x.com'), l10n.validationEmailTooLong);
    });
  });

  group('newPassword', () {
    test('length limits mirror the backend (8..128)', () {
      expect(v.newPassword('1234567'), l10n.validationPasswordTooShort(8));
      expect(v.newPassword('12345678x'), isNull);
      expect(v.newPassword('a' * 128), isNull);
      expect(v.newPassword('a' * 129), l10n.validationPasswordTooLong(128));
      expect(v.newPassword(''), l10n.validationRequired);
    });

    test('must not equal the e-mail name (case-insensitive)', () {
      expect(
        v.newPassword('Somchai.Rider', email: 'somchai.rider@example.com'),
        l10n.validationPasswordSameAsEmail,
      );
      expect(
        v.newPassword('somchai.rider1', email: 'somchai.rider@example.com'),
        isNull,
      );
    });

    test('login only requires a value', () {
      expect(v.loginPassword('x'), isNull);
      expect(v.loginPassword(''), l10n.validationRequired);
    });
  });

  test('confirmPassword must match', () {
    expect(v.confirmPassword('abc', 'abc'), isNull);
    expect(v.confirmPassword('abd', 'abc'), l10n.validationPasswordMismatch);
    expect(v.confirmPassword('', 'abc'), l10n.validationRequired);
  });

  test('displayName is trimmed and limited to 80', () {
    expect(v.displayName('  Somchai '), isNull);
    expect(v.displayName('   '), l10n.validationRequired);
    expect(v.displayName('a' * 80), isNull);
    expect(v.displayName('a' * 81), l10n.validationDisplayNameTooLong(80));
  });

  group('optionalDecimal NUMERIC(6,2)', () {
    String? check(String? value, {bool positive = false}) =>
        v.optionalDecimal(value, maxDigits: 6, places: 2, positive: positive);

    test('empty is allowed', () {
      expect(check(null), isNull);
      expect(check('  '), isNull);
    });

    test('accepts plain decimals within range', () {
      expect(check('45'), isNull);
      expect(check('45.5'), isNull);
      expect(check('.5'), isNull);
      expect(check('9999.99'), isNull);
      expect(
        check('12.50'),
        isNull,
        reason: 'trailing zero is not a 3rd place',
      );
    });

    test('rejects text, exponents, separators', () {
      for (final input in ['abc', '1e3', '1,000', '12.3.4', '+5', '--1']) {
        expect(check(input), l10n.validationNumberInvalid, reason: input);
      }
    });

    test('sign rules', () {
      expect(check('0', positive: true), l10n.validationNumberMustBePositive);
      expect(check('-1', positive: true), l10n.validationNumberMustBePositive);
      expect(check('0'), isNull);
      expect(check('-0.01'), l10n.validationNumberMustNotBeNegative);
    });

    test('scale and precision', () {
      expect(check('1.234'), l10n.validationNumberTooManyDecimals(2));
      expect(check('10000'), l10n.validationNumberTooLarge('9999.99'));
    });
  });

  test('maxDecimal follows NUMERIC(precision, scale)', () {
    expect(maxDecimal(maxDigits: 6, places: 2), Decimal.parse('9999.99'));
    expect(maxDecimal(maxDigits: 8, places: 4), Decimal.parse('9999.9999'));
    expect(maxDecimal(maxDigits: 3, places: 0), Decimal.parse('999'));
  });

  group('TrueProfit rules', () {
    test('requiredDecimal: money NUMERIC(12,2)', () {
      String? money(String? x) =>
          v.requiredDecimal(x, maxDigits: 12, places: 2);
      expect(money(''), l10n.validationRequired);
      expect(money('  '), l10n.validationRequired);
      expect(money('0'), isNull);
      expect(money('800.50'), isNull);
      expect(money('9999999999.99'), isNull);
      expect(
        money('10000000000'),
        l10n.validationNumberTooLarge('9999999999.99'),
      );
      expect(money('1.005'), l10n.validationNumberTooManyDecimals(2));
      expect(money('1,000'), l10n.validationNumberInvalid);
      expect(money('-5'), l10n.validationNumberMustNotBeNegative);
    });

    test('optionalDecimal with a tighter max (hours 0 < h <= 24)', () {
      String? hours(String x) => v.optionalDecimal(
        x,
        maxDigits: 5,
        places: 2,
        positive: true,
        max: Decimal.fromInt(24),
      );
      expect(hours(''), isNull);
      expect(hours('24'), isNull);
      expect(hours('7.5'), isNull);
      expect(hours('24.01'), l10n.validationNumberTooLarge('24'));
      expect(hours('0'), l10n.validationNumberMustBePositive);
    });

    test('optionalInt: whole numbers within range', () {
      String? orders(String x) => v.optionalInt(x, max: 10000);
      expect(orders(''), isNull);
      expect(orders('0'), isNull);
      expect(orders(' 12 '), isNull);
      expect(orders('10000'), isNull);
      expect(orders('10001'), l10n.validationNumberTooLarge('10000'));
      expect(
        orders('99999999999999999999999'),
        l10n.validationNumberTooLarge('10000'),
      );
      expect(orders('1.5'), l10n.validationWholeNumber);
      expect(orders('abc'), l10n.validationWholeNumber);
      expect(orders('-1'), l10n.validationNumberMustNotBeNegative);
      expect(
        v.optionalInt('0', min: 1, max: 5),
        l10n.validationNumberTooSmall('1'),
      );
    });

    test('optionalText counts characters after trimming', () {
      expect(v.optionalText('', max: 3), isNull);
      expect(v.optionalText('  abc  ', max: 3), isNull);
      expect(v.optionalText('abcd', max: 3), l10n.validationTextTooLong(3));
    });
  });
}
