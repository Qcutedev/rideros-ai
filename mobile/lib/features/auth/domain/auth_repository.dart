import 'user.dart';

/// Every method throws an `AppFailure` on error.
abstract interface class AuthRepository {
  /// Creates the account. The backend returns no tokens: call [login] next.
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Stores the token pair and returns the signed-in user.
  Future<User> login({required String email, required String password});

  /// Resumes a stored session (refresh + `GET /me`). `null` when nothing is stored.
  /// Throws `SessionExpiredFailure` when the stored refresh token is rejected.
  Future<User?> restoreSession();

  /// Revokes this login session on the server (best effort) and forgets the tokens.
  Future<void> logout();

  /// Always succeeds (202) unless rate limited or unavailable; never reveals whether
  /// the e-mail has an account.
  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// `PATCH /me`: the only editable account field. Returns the updated user.
  Future<User> updateDisplayName(String displayName);

  /// `DELETE /me` with the password: deletes the account and all of its data on the
  /// server, then forgets the local tokens. Wrong password: 403 `invalid_password`.
  Future<void> deleteAccount(String password);

  /// Fires when the refresh token is rejected during normal use.
  Stream<void> get sessionExpired;
}
