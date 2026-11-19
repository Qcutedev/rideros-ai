/// Typed failures that leave the data layer. Widgets and notifiers never see a
/// `DioException`; they switch over these cases instead.
sealed class AppFailure implements Exception {
  const AppFailure();
}

/// No connection, DNS failure or timeout. Safe to retry.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({this.isTimeout = false});

  final bool isTimeout;

  @override
  String toString() => 'NetworkFailure(timeout: $isTimeout)';
}

/// The refresh token was rejected (expired, revoked or reused). The user must log in again.
final class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure();

  @override
  String toString() => 'SessionExpiredFailure()';
}

/// 429 `rate_limited`. [retryAfter] comes from the `Retry-After` header when present.
final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({this.retryAfter});

  final Duration? retryAfter;

  @override
  String toString() => 'RateLimitedFailure(retryAfter: $retryAfter)';
}

/// Any other error response that carries the API envelope
/// `{"error": {"code", "message", "details"}}`.
final class ApiFailure extends AppFailure {
  const ApiFailure({
    required this.statusCode,
    required this.code,
    this.message = '',
    this.fieldErrors = const {},
    this.details = const [],
  });

  final int statusCode;

  /// Stable machine-readable code such as `invalid_credentials` or `email_taken`.
  final String code;

  /// Server message (English, for logs and debugging; the UI shows its own text).
  final String message;

  /// 422 details keyed by the last element of `loc` (e.g. `email`).
  final Map<String, String> fieldErrors;

  /// The envelope's `details` objects as sent, e.g. `[{"incident_id": "…"}]`
  /// of `already_reported`.
  final List<Map<String, Object?>> details;

  /// First string value of [key] among [details].
  String? detail(String key) {
    for (final item in details) {
      final value = item[key];
      if (value is String) return value;
    }
    return null;
  }

  @override
  String toString() => 'ApiFailure($statusCode, $code)';
}

/// Anything unexpected (malformed response, programming error).
final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.cause]);

  final Object? cause;

  @override
  String toString() => 'UnknownFailure($cause)';
}

/// Error codes the app reacts to. Values match the backend (`backend/README.md`).
abstract final class ApiErrorCode {
  static const invalidCredentials = 'invalid_credentials';
  static const emailTaken = 'email_taken';
  static const weakPassword = 'weak_password';
  static const invalidResetToken = 'invalid_reset_token';
  static const passwordResetUnavailable = 'password_reset_unavailable';
  static const validationError = 'validation_error';
  static const rateLimited = 'rate_limited';
  static const internalError = 'internal_error';
  static const invalidTimezone = 'invalid_timezone';
  static const invalidPassword = 'invalid_password';

  // TrueProfit records.
  static const workSessionOverlap = 'work_session_overlap';
  static const invalidTimeRange = 'invalid_time_range';
  static const workSessionTooLong = 'work_session_too_long';
  static const invalidWorkSession = 'invalid_work_session';

  // Shift simulator.
  static const invalidShiftLength = 'invalid_shift_length';
  static const missingAssumption = 'missing_assumption';
  static const insufficientHistory = 'insufficient_history';

  // Access-token problems: the client refreshes once and retries.
  static const tokenExpired = 'token_expired';
  static const invalidToken = 'invalid_token';
  static const notAuthenticated = 'not_authenticated';
}
