/// The backend writes reset links as `rideros://reset-password?token=<token>` (D5: in the
/// development log). Riders may paste the whole link or only the token.
/// Returns `null` when the input does not contain a plausible token
/// (URL-safe base64, 16–256 characters, matching `ResetPasswordRequest`).
String? extractResetToken(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  var candidate = text;
  final marker = text.indexOf('token=');
  if (marker >= 0) {
    candidate = text.substring(marker + 'token='.length);
    final end = candidate.indexOf(RegExp('[&#\\s]'));
    if (end >= 0) candidate = candidate.substring(0, end);
    candidate = Uri.decodeQueryComponent(candidate);
  }
  return _tokenPattern.hasMatch(candidate) ? candidate : null;
}

final _tokenPattern = RegExp(r'^[A-Za-z0-9_\-]{16,256}$');
