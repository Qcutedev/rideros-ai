import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../profile/data/rider_profile_repository_impl.dart';
import '../../profile/domain/rider_profile_repository.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/session_state.dart';
import '../domain/user.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Single source of truth for "who is signed in". The router guard listens to it.
class SessionController extends Notifier<SessionState> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);
  RiderProfileRepository get _profiles =>
      ref.read(riderProfileRepositoryProvider);

  @override
  SessionState build() {
    final subscription = ref
        .watch(authRepositoryProvider)
        .sessionExpired
        .listen((_) => _onSessionExpired());
    ref.onDispose(subscription.cancel);
    // State cannot change during build; resume the stored session right after it.
    unawaited(Future.microtask(restore));
    return const SessionRestoring();
  }

  /// Resumes the stored session. Called on start and from the splash "retry" button.
  Future<void> restore() async {
    state = const SessionRestoring();
    try {
      final user = await _auth.restoreSession();
      if (!ref.mounted) return;
      state = user == null ? const SignedOut() : await _signedIn(user);
    } on SessionExpiredFailure {
      if (ref.mounted) state = const SignedOut(SignOutReason.sessionExpired);
    } catch (error) {
      if (ref.mounted) state = SessionRestoreFailed(mapToFailure(error));
    }
  }

  /// Throws an `AppFailure` (e.g. `invalid_credentials`); the state stays signed out.
  Future<void> login({required String email, required String password}) async {
    final user = await _auth.login(email: email, password: password);
    final next = await _signedIn(user);
    if (ref.mounted) state = next;
  }

  /// Creates the account only; the caller signs in afterwards with [login].
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) => _auth.register(
    email: email,
    password: password,
    displayName: displayName,
  );

  Future<void> logout() async {
    await _auth.logout();
    if (ref.mounted) state = const SignedOut(SignOutReason.userLoggedOut);
  }

  /// Onboarding saved the rider profile.
  void markProfileConfigured() {
    final current = state;
    if (current is SignedIn) {
      state = current.copyWith(profileConfigured: true);
    }
  }

  Future<SignedIn> _signedIn(User user) async {
    final profile = await _profiles.fetch();
    return SignedIn(user: user, profileConfigured: profile.isConfigured);
  }

  void _onSessionExpired() {
    if (state is! SignedOut) {
      state = const SignedOut(SignOutReason.sessionExpired);
    }
  }
}
