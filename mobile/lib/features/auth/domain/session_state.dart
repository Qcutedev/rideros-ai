import 'user.dart';

/// What the router guard needs to know about the current user.
sealed class SessionState {
  const SessionState();
}

/// App start: reading the stored refresh token and resuming the session.
final class SessionRestoring extends SessionState {
  const SessionRestoring();
}

/// Resuming failed for a reason other than a rejected token (offline, server down).
/// The stored token is kept so a retry can still succeed.
final class SessionRestoreFailed extends SessionState {
  const SessionRestoreFailed(this.failure);

  final Object failure;
}

enum SignOutReason { none, userLoggedOut, sessionExpired, accountDeleted }

final class SignedOut extends SessionState {
  const SignedOut([this.reason = SignOutReason.none]);

  final SignOutReason reason;
}

final class SignedIn extends SessionState {
  const SignedIn({required this.user, required this.profileConfigured});

  final User user;

  /// `false` until the rider profile has been saved once → onboarding.
  final bool profileConfigured;

  SignedIn copyWith({User? user, bool? profileConfigured}) => SignedIn(
    user: user ?? this.user,
    profileConfigured: profileConfigured ?? this.profileConfigured,
  );
}
