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

  test('signed in without a profile: only onboarding (and a reset link)', () {
    for (final path in allPaths) {
      expect(
        redirect(needsOnboarding, path),
        path == Routes.onboarding || path == Routes.resetPassword
            ? isNull
            : Routes.onboarding,
        reason: path,
      );
    }
  });

  test('signed in: auth screens, splash and onboarding → home', () {
    for (final path in allPaths) {
      final expected = path == Routes.home || path == Routes.resetPassword
          ? isNull
          : Routes.home;
      expect(redirect(signedIn, path), expected, reason: path);
    }
  });

  test('query parameters do not change the decision', () {
    expect(redirect(const SignedOut(), '/reset-password?token=abc'), isNull);
    expect(redirect(signedIn, '/login?notice=registered'), Routes.home);
  });

  group('reset link', () {
    final link = Uri.parse('rideros://reset-password?token=abc123');

    test('maps only rideros://reset-password', () {
      expect(
        resetLinkLocation(link).toString(),
        '/reset-password?token=abc123',
      );
      expect(
        resetLinkLocation(Uri.parse('rideros://reset-password')).toString(),
        Routes.resetPassword,
      );
      expect(resetLinkLocation(Uri.parse('rideros://other?token=a')), isNull);
      expect(resetLinkLocation(Uri.parse('https://reset-password/x')), isNull);
      expect(resetLinkLocation(Uri.parse('/reset-password?token=a')), isNull);
    });

    test('opens the reset screen signed out and signed in', () {
      for (final state in [const SignedOut(), signedIn, needsOnboarding]) {
        expect(
          AppRedirect()(state, link),
          '/reset-password?token=abc123',
          reason: '$state',
        );
      }
    });

    test('is kept while restoring and opened afterwards', () {
      final redirect = AppRedirect();
      expect(redirect(const SessionRestoring(), link), Routes.splash);
      expect(
        redirect(
          const SessionRestoreFailed(NetworkFailure()),
          Uri.parse(Routes.splash),
        ),
        isNull,
      );
      expect(
        redirect(signedIn, Uri.parse(Routes.splash)),
        '/reset-password?token=abc123',
      );
      // Used once: the next refresh follows the plain guard again.
      expect(redirect(signedIn, Uri.parse(Routes.splash)), Routes.home);
    });

    test('other locations are left to the guard', () {
      final redirect = AppRedirect();
      expect(redirect(signedIn, Uri.parse(Routes.home)), isNull);
      expect(redirect(signedIn, Uri.parse(Routes.login)), Routes.home);
      expect(redirect(const SignedOut(), Uri.parse(Routes.home)), Routes.login);
    });
  });
}
