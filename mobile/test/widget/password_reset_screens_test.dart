import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:rideros_ai/features/auth/presentation/reset_password_screen.dart';
import 'package:rideros_ai/features/auth/presentation/session_controller.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

const _token = 'AbCdEf0123456789_-xyzXYZ0123456789abcdefghi'; // gitleaks:allow (fake test token)

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('forgot password', () {
    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      path: Routes.forgotPassword,
      screen: const ForgotPasswordScreen(),
      overrides: fakeRepositories(auth),
    );

    testWidgets('validates the e-mail', (tester) async {
      await pump(tester);
      await tapKey(tester, 'forgot.submit');
      expect(find.text(t.validationRequired), findsOneWidget);
      await enter(tester, 'forgot.email', 'nope');
      await tapKey(tester, 'forgot.submit');
      expect(find.text(t.validationEmailInvalid), findsOneWidget);
      expect(auth.calls, isNot(contains('forgot')));
    });

    testWidgets('success shows the neutral sent message and the dev note', (
      tester,
    ) async {
      await pump(tester);
      await enter(tester, 'forgot.email', 'rider@example.com');
      await tapKey(tester, 'forgot.submit');
      expect(auth.lastArgs['email'], 'rider@example.com');
      expect(find.text(t.forgotSentTitle), findsOneWidget);
      expect(find.text(t.forgotSentMessage), findsOneWidget);
      expect(find.text(t.forgotDevNote), findsOneWidget);

      await tapKey(tester, 'forgot.sent.haveToken');
      expect(find.text('route:${Routes.resetPassword}'), findsOneWidget);
    });

    testWidgets('sent view can go back to login', (tester) async {
      await pump(tester);
      await enter(tester, 'forgot.email', 'rider@example.com');
      await tapKey(tester, 'forgot.submit');
      await tapKey(tester, 'forgot.sent.login');
      expect(find.text('route:${Routes.login}'), findsOneWidget);
    });

    testWidgets('unavailable in production shows its message', (tester) async {
      auth.forgotError = const ApiFailure(
        statusCode: 503,
        code: ApiErrorCode.passwordResetUnavailable,
      );
      await pump(tester);
      await enter(tester, 'forgot.email', 'rider@example.com');
      await tapKey(tester, 'forgot.submit');
      expect(find.text(t.failurePasswordResetUnavailable), findsOneWidget);
      expect(find.text(t.forgotSentTitle), findsNothing);
    });

    testWidgets('"have a link" goes straight to reset', (tester) async {
      await pump(tester);
      await tapKey(tester, 'forgot.haveToken');
      expect(find.text('route:${Routes.resetPassword}'), findsOneWidget);
    });
  });

  group('reset password', () {
    Future<void> pump(WidgetTester tester, {String? token}) => pumpScreen(
      tester,
      path: Routes.resetPassword,
      screen: ResetPasswordScreen(initialToken: token),
      overrides: fakeRepositories(auth),
    );

    testWidgets('validates token and passwords', (tester) async {
      await pump(tester);
      await enter(tester, 'reset.token', 'not a token');
      await enter(tester, 'reset.password', 'short');
      await enter(tester, 'reset.confirm', 'different');
      await tapKey(tester, 'reset.submit');
      expect(find.text(t.validationResetTokenInvalid), findsOneWidget);
      expect(find.text(t.validationPasswordTooShort(8)), findsOneWidget);
      expect(find.text(t.validationPasswordMismatch), findsOneWidget);
      expect(auth.calls, isNot(contains('reset')));
    });

    testWidgets('a pasted link is reduced to the token; success → login', (
      tester,
    ) async {
      await pump(tester);
      await enter(
        tester,
        'reset.token',
        'rideros://reset-password?token=$_token',
      );
      await enter(tester, 'reset.password', 'new pass 123');
      await enter(tester, 'reset.confirm', 'new pass 123');
      await tapKey(tester, 'reset.submit');
      expect(auth.lastArgs['token'], _token);
      expect(auth.lastArgs['newPassword'], 'new pass 123');
      expect(auth.calls, isNot(contains('logout')));
      expect(
        find.text('route:${Routes.login}?notice=${LoginNotice.passwordReset}'),
        findsOneWidget,
      );
    });

    testWidgets('signed in (opened from the e-mail link): success signs out '
        'this device too → login', (tester) async {
      auth.restoreUser = testUser;
      await pump(tester, token: _token);
      // Restore the stored session before the reset (signed in).
      ProviderScope.containerOf(tester.element(find.byType(Scaffold)))
          .listen(sessionControllerProvider, (_, _) {});
      await tester.pumpAndSettle();
      await enter(tester, 'reset.password', 'new pass 123');
      await enter(tester, 'reset.confirm', 'new pass 123');
      await tapKey(tester, 'reset.submit');
      expect(auth.calls, containsAllInOrder(['reset', 'logout']));
      expect(
        find.text('route:${Routes.login}?notice=${LoginNotice.passwordReset}'),
        findsOneWidget,
      );
    });

    testWidgets('token from the route is pre-filled', (tester) async {
      await pump(tester, token: _token);
      expect(find.text(_token), findsOneWidget);
    });

    testWidgets('expired or used token shows its message', (tester) async {
      auth.resetError = const ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.invalidResetToken,
      );
      await pump(tester, token: _token);
      await enter(tester, 'reset.password', 'new pass 123');
      await enter(tester, 'reset.confirm', 'new pass 123');
      await tapKey(tester, 'reset.submit');
      expect(find.text(t.failureInvalidResetToken), findsOneWidget);
    });
  });
}
