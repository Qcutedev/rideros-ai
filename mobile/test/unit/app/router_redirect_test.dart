import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/auth/domain/session_state.dart';

import '../../helpers/fakes.dart';

void main() {
  final signedIn = SignedIn(user: testUser, profileConfigured: true);
  final needsOnboarding = SignedIn(user: testUser, profileConfigured: false);
  const allPaths = [
    Routes.splash,
    Routes.login,
    Routes.register,
    Routes.forgotPassword,
    Routes.resetPassword,
    Routes.onboarding,
    Routes.home,
  ];

  String? redirect(SessionState s, String path) =>
      authRedirect(s, Uri.parse(path));

  test('while restoring (or failed) everything goes to splash', () {
    for (final state in [
      const SessionRestoring(),
      const SessionRestoreFailed(NetworkFailure()),
    ]) {
      for (final path in allPaths) {
        expect(
          redirect(state, path),
          path == Routes.splash ? isNull : Routes.splash,
          reason: '$state $path',
        );
      }
    }
  });

  test('signed out: public screens stay, everything else → login', () {
    for (final path in allPaths) {
      expect(
        redirect(const SignedOut(), path),
        Routes.public.contains(path) ? isNull : Routes.login,
        reason: path,
      );
    }
  });

  test('signed in without a profile: only onboarding', () {
    for (final path in allPaths) {
      expect(
        redirect(needsOnboarding, path),
        path == Routes.onboarding ? isNull : Routes.onboarding,
        reason: path,
      );
    }
  });

  test('signed in: auth screens, splash and onboarding → home', () {
    for (final path in allPaths) {
      final expected = path == Routes.home ? isNull : Routes.home;
      expect(redirect(signedIn, path), expected, reason: path);
    }
  });

  test('query parameters do not change the decision', () {
    expect(redirect(const SignedOut(), '/reset-password?token=abc'), isNull);
    expect(redirect(signedIn, '/login?notice=registered'), Routes.home);
  });
}
