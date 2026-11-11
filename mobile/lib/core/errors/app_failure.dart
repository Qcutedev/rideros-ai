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
  });

  final int statusCode;

  /// Stable machine-readable code such as `invalid_credentials` or `email_taken`.
  final String code;

  /// Server message (English, for logs and debugging; the UI shows its own text).
  final String message;

  /// 422 details keyed by the last element of `loc` (e.g. `email`).
  final Map<String, String> fieldErrors;

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

  // Pickup.
  static const modelUnavailable = 'model_unavailable';
  static const restaurantNotSupported = 'restaurant_not_supported';
  static const invalidPickupTimes = 'invalid_pickup_times';
  static const pickupWaitTooLong = 'pickup_wait_too_long';

  // Access-token problems: the client refreshes once and retries.
  static const tokenExpired = 'token_expired';
  static const invalidToken = 'invalid_token';
  static const notAuthenticated = 'not_authenticated';
}
