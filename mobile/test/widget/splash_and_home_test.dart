import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/auth/presentation/splash_screen.dart';
import 'package:rideros_ai/features/dashboard/presentation/home_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  testWidgets(
    'splash shows the brand and a progress indicator while restoring',
    (tester) async {
      auth.restoreGate = Completer<void>();
      await pumpScreen(
        tester,
        path: Routes.splash,
        screen: const SplashScreen(),
        overrides: fakeRepositories(auth),
        settle: false,
      );
      expect(find.text(t.appTitle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      auth.restoreGate!.complete();
    },
  );

  testWidgets('splash shows the error with a working retry', (tester) async {
    auth.restoreError = const NetworkFailure();
    await pumpScreen(
      tester,
      path: Routes.splash,
      screen: const SplashScreen(),
      overrides: fakeRepositories(auth),
    );
    expect(find.text(t.splashRestoreFailedTitle), findsOneWidget);
    expect(find.text(t.failureNetwork), findsOneWidget);

    auth.restoreError = null;
    auth.restoreGate = Completer<void>();
    await tester.tap(find.text(t.commonRetry));
    await tester.pump();
    expect(auth.calls.where((c) => c == 'restore'), hasLength(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.restoreGate!.complete();
  });

  testWidgets('home greets the user', (tester) async {
    auth.restoreUser = testUser;
    await pumpScreen(
      tester,
      path: Routes.home,
      screen: const HomeScreen(),
      overrides: fakeRepositories(
        auth,
        FakeRiderProfileRepository(configured: true),
      ),
    );
    expect(find.text(t.homeHello), findsOneWidget);
    expect(find.text(testUser.displayName), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(t.homeGreeting(testUser.displayName))),
      findsOneWidget,
    );
  });
}
