import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/auth/domain/session_state.dart';
import 'package:rideros_ai/features/auth/presentation/auth_form_controllers.dart';
import 'package:rideros_ai/features/auth/presentation/session_controller.dart';
import 'package:rideros_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rideros_ai/features/profile/domain/rider_profile.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeRiderProfileRepository profiles;

  ProviderContainer makeContainer() => ProviderContainer.test(
    retry: (retryCount, error) => null,
    overrides: fakeRepositories(auth, profiles),
  );

  /// Reads the session and lets the start-up restore finish.
  Future<ProviderContainer> started() async {
    final container = makeContainer();
    container.listen(sessionControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeRiderProfileRepository();
  });

  group('restore on start', () {
    test('starts as restoring', () {
      auth.restoreGate = Completer<void>();
      final container = makeContainer();
      expect(
        container.read(sessionControllerProvider),
        isA<SessionRestoring>(),
      );
    });

    test('nothing stored → signed out', () async {
      final container = await started();
      expect(container.read(sessionControllerProvider), isA<SignedOut>());
    });

    test('stored session → signed in with the profile flag', () async {
      auth.restoreUser = testUser;
      profiles.configured = true;
      final container = await started();
      final state = container.read(sessionControllerProvider);
      expect(
        state,
        isA<SignedIn>()
            .having((s) => s.user.email, 'email', testUser.email)
            .having((s) => s.profileConfigured, 'configured', isTrue),
      );
    });

    test('rejected refresh token → signed out (session expired)', () async {
      auth.restoreError = const SessionExpiredFailure();
      final container = await started();
      expect(
        container.read(sessionControllerProvider),
        isA<SignedOut>().having(
          (s) => s.reason,
          'reason',
          SignOutReason.sessionExpired,
        ),
      );
    });

    test('offline → restore failed, retry succeeds', () async {
      auth.restoreError = const NetworkFailure();
      final container = await started();
      expect(
        container.read(sessionControllerProvider),
        isA<SessionRestoreFailed>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      );

      auth
        ..restoreError = null
        ..restoreUser = testUser;
      await container.read(sessionControllerProvider.notifier).restore();
      expect(container.read(sessionControllerProvider), isA<SignedIn>());
    });
  });

  test('login → signed in; profile not configured → onboarding flag', () async {
    final container = await started();
    await container
        .read(sessionControllerProvider.notifier)
        .login(email: 'rider@example.com', password: 'pw');
    expect(
      container.read(sessionControllerProvider),
      isA<SignedIn>().having((s) => s.profileConfigured, 'configured', false),
    );
  });

  test('failed login keeps the state signed out and rethrows', () async {
    auth.loginError = invalidCredentials;
    final container = await started();
    await expectLater(
      container
          .read(sessionControllerProvider.notifier)
          .login(email: 'rider@example.com', password: 'bad'),
      throwsA(isA<ApiFailure>()),
    );
    expect(container.read(sessionControllerProvider), isA<SignedOut>());
  });

  test('a session that expires during use returns to signed out', () async {
    auth.restoreUser = testUser;
    final container = await started();
    auth.expireSession();
    await pumpEventQueue();
    expect(
      container.read(sessionControllerProvider),
      isA<SignedOut>().having(
        (s) => s.reason,
        'reason',
        SignOutReason.sessionExpired,
      ),
    );
  });

  test('logout', () async {
    auth.restoreUser = testUser;
    final container = await started();
    await container.read(sessionControllerProvider.notifier).logout();
    expect(auth.calls, contains('logout'));
    expect(
      container.read(sessionControllerProvider),
      isA<SignedOut>().having(
        (s) => s.reason,
        'reason',
        SignOutReason.userLoggedOut,
      ),
    );
  });

  group('form controllers', () {
    test('login controller: loading, then error as AppFailure', () async {
      auth
        ..loginError = invalidCredentials
        ..loginGate = Completer<void>();
      final container = await started();
      final sub = container.listen(loginControllerProvider, (_, _) {});
      addTearDown(sub.close);

      final result = container
          .read(loginControllerProvider.notifier)
          .submit(email: 'rider@example.com', password: 'bad');
      expect(container.read(loginControllerProvider).isLoading, isTrue);
      // A second submit while running is ignored.
      expect(
        await container
            .read(loginControllerProvider.notifier)
            .submit(email: 'x@y.z', password: 'x'),
        isFalse,
      );
      auth.loginGate!.complete();
      expect(await result, isFalse);
      expect(auth.calls.where((c) => c == 'login'), hasLength(1));
      expect(container.read(loginControllerProvider).error, isA<ApiFailure>());
    });

    test('register then login → signedIn', () async {
      final container = await started();
      final sub = container.listen(registerControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final outcome = await container
          .read(registerControllerProvider.notifier)
          .submit(
            displayName: 'Somchai',
            email: 'new@example.com',
            password: 'pass word 1',
          );
      expect(outcome, RegisterOutcome.signedIn);
      expect(auth.calls, ['restore', 'register', 'login']);
      expect(container.read(sessionControllerProvider), isA<SignedIn>());
    });

    test(
      'register ok but login fails → registeredOnly, no error state',
      () async {
        auth.loginError = const RateLimitedFailure();
        final container = await started();
        final sub = container.listen(registerControllerProvider, (_, _) {});
        addTearDown(sub.close);
        final outcome = await container
            .read(registerControllerProvider.notifier)
            .submit(
              displayName: 'Somchai',
              email: 'new@example.com',
              password: 'pass word 1',
            );
        expect(outcome, RegisterOutcome.registeredOnly);
        expect(container.read(registerControllerProvider).hasError, isFalse);
        expect(container.read(sessionControllerProvider), isA<SignedOut>());
      },
    );

    test('register failure → null outcome and error state', () async {
      auth.registerError = const ApiFailure(
        statusCode: 409,
        code: ApiErrorCode.emailTaken,
      );
      final container = await started();
      final sub = container.listen(registerControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final outcome = await container
          .read(registerControllerProvider.notifier)
          .submit(
            displayName: 'Somchai',
            email: 'taken@example.com',
            password: 'pass word 1',
          );
      expect(outcome, isNull);
      expect(
        container.read(registerControllerProvider).error,
        isA<ApiFailure>().having((f) => f.code, 'code', 'email_taken'),
      );
    });

    test('onboarding save marks the profile configured', () async {
      auth.restoreUser = testUser;
      final container = await started();
      final sub = container.listen(onboardingControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final ok = await container
          .read(onboardingControllerProvider.notifier)
          .submit(const RiderProfileInput(vehicleType: VehicleType.car));
      expect(ok, isTrue);
      expect(profiles.lastSaved?.vehicleType, VehicleType.car);
      expect(
        container.read(sessionControllerProvider),
        isA<SignedIn>().having((s) => s.profileConfigured, 'configured', true),
      );
    });

    test('onboarding failure keeps onboarding', () async {
      auth.restoreUser = testUser;
      profiles.saveError = const NetworkFailure();
      final container = await started();
      final sub = container.listen(onboardingControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final ok = await container
          .read(onboardingControllerProvider.notifier)
          .submit(const RiderProfileInput());
      expect(ok, isFalse);
      expect(
        container.read(sessionControllerProvider),
        isA<SignedIn>().having((s) => s.profileConfigured, 'configured', false),
      );
    });
  });

  group('account', () {
    setUp(() => auth.restoreUser = testUser);

    test('updateDisplayName replaces the signed-in user', () async {
      final container = await started();
      await container
          .read(sessionControllerProvider.notifier)
          .updateDisplayName('Somsak');
      final state = container.read(sessionControllerProvider) as SignedIn;
      expect(state.user.displayName, 'Somsak');
      expect(state.profileConfigured, isFalse, reason: 'kept as it was');
    });

    test('a failed rename keeps the old name and rethrows', () async {
      auth.updateNameError = const NetworkFailure();
      final container = await started();
      await expectLater(
        container
            .read(sessionControllerProvider.notifier)
            .updateDisplayName('Somsak'),
        throwsA(isA<NetworkFailure>()),
      );
      final state = container.read(sessionControllerProvider) as SignedIn;
      expect(state.user.displayName, testUser.displayName);
    });

    test('deleteAccount signs out with its own reason', () async {
      final container = await started();
      await container
          .read(sessionControllerProvider.notifier)
          .deleteAccount('secret pw');
      expect(auth.lastArgs['password'], 'secret pw');
      expect(
        container.read(sessionControllerProvider),
        isA<SignedOut>().having(
          (s) => s.reason,
          'reason',
          SignOutReason.accountDeleted,
        ),
      );
    });

    test('a wrong password keeps the user signed in', () async {
      auth.deleteError = const ApiFailure(
        statusCode: 403,
        code: ApiErrorCode.invalidPassword,
      );
      final container = await started();
      await expectLater(
        container.read(sessionControllerProvider.notifier).deleteAccount('x'),
        throwsA(isA<ApiFailure>()),
      );
      expect(container.read(sessionControllerProvider), isA<SignedIn>());
    });
  });
}
