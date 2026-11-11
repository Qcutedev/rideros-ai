import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/auth/presentation/login_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  Future<void> pump(WidgetTester tester, {String? notice}) => pumpScreen(
    tester,
    path: Routes.login,
    screen: LoginScreen(notice: notice),
    overrides: fakeRepositories(auth),
  );

  testWidgets('empty submit shows required errors and does not call the API', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'login.submit');
    expect(find.text(t.validationRequired), findsNWidgets(2));
    expect(auth.calls, isNot(contains('login')));
  });

  testWidgets('malformed e-mail is rejected', (tester) async {
    await pump(tester);
    await enter(tester, 'login.email', 'rider');
    await enter(tester, 'login.password', 'secret');
    await tapKey(tester, 'login.submit');
    expect(find.text(t.validationEmailInvalid), findsOneWidget);
    expect(auth.calls, isNot(contains('login')));
  });

  testWidgets('valid input logs in with the typed values', (tester) async {
    await pump(tester);
    await enter(tester, 'login.email', 'rider@example.com');
    await enter(tester, 'login.password', 'secret pw');
    await tapKey(tester, 'login.submit');
    expect(auth.calls, contains('login'));
    expect(auth.lastArgs['email'], 'rider@example.com');
    expect(auth.lastArgs['password'], 'secret pw');
  });

  testWidgets('shows a loading button while signing in', (tester) async {
    auth.loginGate = Completer<void>();
    await pump(tester);
    await enter(tester, 'login.email', 'rider@example.com');
    await enter(tester, 'login.password', 'secret pw');
    await tapKey(tester, 'login.submit', settle: false);
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('login.submit')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.loginGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('wrong credentials show the Thai message', (tester) async {
    auth.loginError = invalidCredentials;
    await pump(tester);
    await enter(tester, 'login.email', 'rider@example.com');
    await enter(tester, 'login.password', 'wrong');
    await tapKey(tester, 'login.submit');
    expect(find.text(t.failureInvalidCredentials), findsOneWidget);
  });

  testWidgets('rate limiting shows the Retry-After seconds', (tester) async {
    auth.loginError = const RateLimitedFailure(
      retryAfter: Duration(seconds: 42),
    );
    await pump(tester);
    await enter(tester, 'login.email', 'rider@example.com');
    await enter(tester, 'login.password', 'pw');
    await tapKey(tester, 'login.submit');
    expect(find.text(t.failureRateLimited(42)), findsOneWidget);
  });

  testWidgets('offline shows the network message', (tester) async {
    auth.loginError = const NetworkFailure();
    await pump(tester);
    await enter(tester, 'login.email', 'rider@example.com');
    await enter(tester, 'login.password', 'pw');
    await tapKey(tester, 'login.submit');
    expect(find.text(t.failureNetwork), findsOneWidget);
  });

  testWidgets('session-expired banner', (tester) async {
    auth.restoreError = const SessionExpiredFailure();
    await pump(tester);
    expect(find.text(t.loginSessionExpired), findsOneWidget);
  });

  testWidgets('notices after register and password reset', (tester) async {
    await pump(tester, notice: LoginNotice.registered);
    expect(find.text(t.loginRegisteredPleaseLogin), findsOneWidget);
  });

  testWidgets('password-reset notice', (tester) async {
    await pump(tester, notice: LoginNotice.passwordReset);
    expect(find.text(t.loginPasswordResetDone), findsOneWidget);
  });

  testWidgets('links open register and forgot password', (tester) async {
    await pump(tester);
    await tapKey(tester, 'login.register');
    expect(find.text('route:${Routes.register}'), findsOneWidget);
  });

  testWidgets('forgot password link', (tester) async {
    await pump(tester);
    await tapKey(tester, 'login.forgot');
    expect(find.text('route:${Routes.forgotPassword}'), findsOneWidget);
  });

  testWidgets('password visibility toggle', (tester) async {
    await pump(tester);
    EditableText field() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('login.password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip(t.showPassword));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });
}
