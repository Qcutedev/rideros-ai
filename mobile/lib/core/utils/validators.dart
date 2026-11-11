import 'package:decimal/decimal.dart';

import '../../l10n/app_localizations.dart';

/// Client-side checks that mirror the backend rules (`backend/app/core/security.py`,
/// Pydantic schemas). The server stays the authority: common-password checks run there.
abstract final class AuthRules {
  static const passwordMinLength = 8;
  static const passwordMaxLength = 128;
  static const emailMaxLength = 254;
  static const displayNameMaxLength = 80;
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class Validators {
  const Validators(this.l10n);

  final AppLocalizations l10n;

  String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? l10n.validationRequired : null;

  String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.validationRequired;
    if (v.length > AuthRules.emailMaxLength) return l10n.validationEmailTooLong;
    if (!_emailPattern.hasMatch(v)) return l10n.validationEmailInvalid;
    return null;
  }

  /// Login only needs a value: the backend answers `invalid_credentials` for anything else.
  String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? l10n.validationRequired : null;

  /// New password (register, reset). [email] enables the "same as e-mail name" rule.
  String? newPassword(String? value, {String? email}) {
    final v = value ?? '';
    if (v.isEmpty) return l10n.validationRequired;
    if (v.length < AuthRules.passwordMinLength) {
      return l10n.validationPasswordTooShort(AuthRules.passwordMinLength);
    }
    if (v.length > AuthRules.passwordMaxLength) {
      return l10n.validationPasswordTooLong(AuthRules.passwordMaxLength);
    }
    final localPart = email?.trim().split('@').first.toLowerCase();
    if (localPart != null &&
        localPart.isNotEmpty &&
        v.toLowerCase() == localPart) {
      return l10n.validationPasswordSameAsEmail;
    }
    return null;
  }

  String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return l10n.validationRequired;
    return value == password ? null : l10n.validationPasswordMismatch;
  }

  String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.validationRequired;
    if (v.length > AuthRules.displayNameMaxLength) {
      return l10n.validationDisplayNameTooLong(AuthRules.displayNameMaxLength);
    }
    return null;
  }

  /// Optional decimal field matching a `NUMERIC(maxDigits, places)` column.
  /// Empty is valid (null). [positive] means > 0, otherwise >= 0. [max] is a
  /// tighter upper bound than the column allows (e.g. 24 hours).
  String? optionalDecimal(
    String? value, {
    required int maxDigits,
    required int places,
    bool positive = false,
    Decimal? max,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final parsed = parseDecimalInput(v);
    if (parsed == null) return l10n.validationNumberInvalid;
    if (positive && parsed <= Decimal.zero) {
      return l10n.validationNumberMustBePositive;
    }
    if (parsed < Decimal.zero) return l10n.validationNumberMustNotBeNegative;
    if ((parsed.scale) > places) {
      return l10n.validationNumberTooManyDecimals(places);
    }
    final limit = max ?? maxDecimal(maxDigits: maxDigits, places: places);
    if (parsed > limit) return l10n.validationNumberTooLarge(limit.toString());
    return null;
  }

  /// Required decimal (e.g. an amount of money); same rules as [optionalDecimal].
  String? requiredDecimal(
    String? value, {
    required int maxDigits,
    required int places,
    bool positive = false,
  }) =>
      required(value) ??
      optionalDecimal(
        value,
        maxDigits: maxDigits,
        places: places,
        positive: positive,
      );

  /// Optional whole number within [min]..[max].
  String? optionalInt(String? value, {int min = 0, required int max}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^-?\d+$').hasMatch(v)) return l10n.validationWholeNumber;
    final parsed = int.tryParse(v);
    if (parsed == null || parsed > max) {
      return l10n.validationNumberTooLarge(max.toString());
    }
    if (parsed < min) {
      return min == 0
          ? l10n.validationNumberMustNotBeNegative
          : l10n.validationNumberTooSmall(min.toString());
    }
    return null;
  }

  /// Optional free text of at most [max] characters (after trimming, like the API).
  String? optionalText(String? value, {required int max}) {
    final v = value?.trim() ?? '';
    return v.length > max ? l10n.validationTextTooLong(max) : null;
  }
}

/// Plain decimal notation only (`12`, `12.5`, `.5`); no exponents, signs other than `-`,
/// or thousands separators.
final _decimalPattern = RegExp(r'^-?(\d+\.?\d*|\.\d+)$');

Decimal? parseDecimalInput(String input) {
  final v = input.trim();
  if (!_decimalPattern.hasMatch(v)) return null;
  return Decimal.tryParse(v);
}

/// Largest value of `NUMERIC(maxDigits, places)`, e.g. (6, 2) -> 9999.99.
Decimal maxDecimal({required int maxDigits, required int places}) {
  final integerDigits = maxDigits - places;
  final integer = integerDigits > 0 ? '9' * integerDigits : '0';
  return Decimal.parse(places > 0 ? '$integer.${'9' * places}' : integer);
}
