import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/features/auth/domain/reset_token.dart';

void main() {
  const token = 'AbCdEf0123456789_-xyzXYZ0123456789abcdefghi'; // gitleaks:allow (fake test token)

  test('accepts the bare token', () {
    expect(extractResetToken(token), token);
    expect(extractResetToken('  $token\n'), token);
  });

  test('extracts the token from the backend link', () {
    expect(extractResetToken('rideros://reset-password?token=$token'), token);
    expect(
      extractResetToken('https://x.example/reset?a=1&token=$token&b=2'),
      token,
    );
    expect(
      extractResetToken('reset_link=rideros://reset-password?token=$token "x"'),
      token,
    );
  });

  test('rejects text that is not a plausible token', () {
    expect(extractResetToken(''), isNull);
    expect(extractResetToken('short'), isNull);
    expect(extractResetToken('rideros://reset-password?token='), isNull);
    expect(extractResetToken('has spaces in it 0123456789'), isNull);
    expect(extractResetToken('a' * 257), isNull);
  });
}
