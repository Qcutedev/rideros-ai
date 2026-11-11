import '../../l10n/app_localizations.dart';
import 'app_failure.dart';

/// User-facing (Thai) text for a failure. Server messages are English and only logged.
String failureMessage(AppLocalizations l10n, AppFailure failure) =>
    switch (failure) {
      NetworkFailure(isTimeout: true) => l10n.failureTimeout,
      NetworkFailure() => l10n.failureNetwork,
      SessionExpiredFailure() => l10n.failureSessionExpired,
      RateLimitedFailure(:final retryAfter?) => l10n.failureRateLimited(
        retryAfter.inSeconds < 1 ? 1 : retryAfter.inSeconds,
      ),
      RateLimitedFailure() => l10n.failureRateLimitedNoTime,
      ApiFailure() => _apiMessage(l10n, failure),
      UnknownFailure() => l10n.failureUnknown,
    };

String _apiMessage(AppLocalizations l10n, ApiFailure failure) =>
    switch (failure.code) {
      ApiErrorCode.invalidCredentials => l10n.failureInvalidCredentials,
      ApiErrorCode.emailTaken => l10n.failureEmailTaken,
      ApiErrorCode.weakPassword => l10n.failureWeakPassword,
      ApiErrorCode.invalidResetToken => l10n.failureInvalidResetToken,
      ApiErrorCode.passwordResetUnavailable =>
        l10n.failurePasswordResetUnavailable,
      ApiErrorCode.invalidTimezone => l10n.failureInvalidTimezone,
      ApiErrorCode.invalidPassword => l10n.failureInvalidPassword,
      ApiErrorCode.validationError => l10n.failureValidation,
      ApiErrorCode.workSessionOverlap => l10n.failureWorkSessionOverlap,
      ApiErrorCode.invalidTimeRange => l10n.failureInvalidTimeRange,
      ApiErrorCode.workSessionTooLong => l10n.failureWorkSessionTooLong,
      ApiErrorCode.invalidWorkSession => l10n.failureInvalidWorkSession,
      ApiErrorCode.modelUnavailable => l10n.failureModelUnavailable,
      ApiErrorCode.restaurantNotSupported => l10n.failureRestaurantNotSupported,
      ApiErrorCode.invalidPickupTimes => l10n.failureInvalidPickupTimes,
      ApiErrorCode.pickupWaitTooLong => l10n.failurePickupWaitTooLong,
      // `income_not_found`, `expense_not_found`, `work_session_not_found`,
      // `restaurant_not_found`, `pickup_log_not_found`, `not_found`.
      _ when failure.statusCode == 404 => l10n.failureNotFound,
      _ when failure.statusCode >= 500 => l10n.failureServer,
      _ => l10n.failureUnknown,
    };
