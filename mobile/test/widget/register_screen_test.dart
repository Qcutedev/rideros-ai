import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/auth/presentation/register_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  Future<void> pump(WidgetTester tester) => pumpScreen(
    tester,
    path: Routes.register,
    screen: const RegisterScreen(),
    overrides: fakeRepositories(auth),
  );

  Future<void> fill(
    WidgetTester tester, {
    String name = 'Somchai',
    String email = 'new@example.com',
    String password = 'pass word 1',
    String? confirm,
  }) async {
    await enter(tester, 'register.displayName', name);
    await enter(tester, 'register.email', email);
    await enter(tester, 'register.password', password);
    await enter(tester, 'register.confirm', confirm ?? password);
  }

  testWidgets('empty submit shows required errors', (tester) async {
    await pump(tester);
    await tapKey(tester, 'register.submit');
    expect(find.text(t.validationRequired), findsNWidgets(4));
    expect(auth.calls, isNot(contains('register')));
  });

  testWidgets('short password and mismatch are rejected', (tester) async {
    await pump(tester);
    await fill(tester, password: 'short', confirm: 'shorter');
    await tapKey(tester, 'register.submit');
    expect(find.text(t.validationPasswordTooShort(8)), findsOneWidget);
    expect(find.text(t.validationPasswordMismatch), findsOneWidget);
    expect(auth.calls, isNot(contains('register')));
  });

  testWidgets('password equal to the e-mail name is rejected', (tester) async {
    await pump(tester);
    await fill(
      tester,
      email: 'somchai.rider@example.com',
      password: 'somchai.rider',
    );
    await tapKey(tester, 'register.submit');
    expect(find.text(t.validationPasswordSameAsEmail), findsOneWidget);
  });

  testWidgets('valid form registers and then signs in', (tester) async {
    await pump(tester);
    await fill(tester, name: '  Somchai  ');
    await tapKey(tester, 'register.submit');
    expect(auth.calls.where((c) => c != 'restore'), ['register', 'login']);
    expect(auth.lastArgs['displayName'], '  Somchai  ');
  });

  testWidgets('if the follow-up login fails, continue on login with a notice', (
    tester,
  ) async {
    auth.loginError = const RateLimitedFailure();
    await pump(tester);
    await fill(tester);
    await tapKey(tester, 'register.submit');
    expect(
      find.text('route:${Routes.login}?notice=${LoginNotice.registered}'),
      findsOneWidget,
    );
  });

  testWidgets('e-mail already used', (tester) async {
    auth.registerError = const ApiFailure(
      statusCode: 409,
      code: ApiErrorCode.emailTaken,
    );
    await pump(tester);
    await fill(tester);
    await tapKey(tester, 'register.submit');
    expect(find.text(t.failureEmailTaken), findsOneWidget);
  });

  testWidgets('weak password from the server', (tester) async {
    auth.registerError = const ApiFailure(
      statusCode: 400,
      code: ApiErrorCode.weakPassword,
    );
    await pump(tester);
    await fill(tester, password: 'password');
    await tapKey(tester, 'register.submit');
    expect(find.text(t.failureWeakPassword), findsOneWidget);
  });

  testWidgets('link back to login', (tester) async {
    await pump(tester);
    await tapKey(tester, 'register.login');
    expect(find.text('route:${Routes.login}'), findsOneWidget);
  });
}
