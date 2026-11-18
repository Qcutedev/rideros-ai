import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/routes.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/auth/domain/session_state.dart';
import 'package:rideros_ai/features/auth/presentation/session_controller.dart';
import 'package:rideros_ai/features/profile/domain/rider_profile.dart';
import 'package:rideros_ai/features/profile/presentation/about_screen.dart';
import 'package:rideros_ai/features/profile/presentation/delete_account_screen.dart';
import 'package:rideros_ai/features/profile/presentation/display_name_screen.dart';
import 'package:rideros_ai/features/profile/presentation/profile_providers.dart';
import 'package:rideros_ai/features/profile/presentation/profile_screen.dart';
import 'package:rideros_ai/features/profile/presentation/rider_profile_form_screen.dart';
import 'package:rideros_ai/features/profit/presentation/profit_providers.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

final _configured = RiderProfile(
  vehicleType: VehicleType.motorcycle,
  fuelKmPerLiter: Decimal.parse('45.5'),
  fuelPricePerLiter: Decimal.parse('38.5'),
  depreciationPerKm: Decimal.parse('0.125'),
  isConfigured: true,
);

void main() {
  late FakeAuthRepository auth;
  late FakeRiderProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository()..restoreUser = testUser;
    profiles = FakeRiderProfileRepository(
      configured: true,
      profile: _configured,
    );
  });

  ProviderContainer containerOf(WidgetTester tester, Type screen) =>
      ProviderScope.containerOf(tester.element(find.byType(screen)));

  group('profile tab', () {
    Future<void> pumpProfile(WidgetTester tester) => pumpScreen(
      tester,
      path: Routes.profile,
      screen: const ProfileScreen(),
      overrides: fakeRepositories(auth, profiles),
    );

    testWidgets('shows the account, vehicle costs, zone and currency', (
      tester,
    ) async {
      await pumpProfile(tester);
      expect(find.text(testUser.displayName), findsNWidgets(2));
      expect(find.text(testUser.email), findsOneWidget);
      expect(find.text(t.profileMemberSince('10 พ.ย. 2026')), findsOneWidget);
      expect(
        find.text(
          'มอเตอร์ไซค์ · 45.5 กม./ลิตร · น้ำมัน ฿38.50/ลิตร · '
          'ค่าเสื่อม ฿0.125/กม.',
        ),
        findsOneWidget,
      );
      expect(find.text('Asia/Bangkok'), findsOneWidget);
      expect(find.text('THB'), findsOneWidget);
    });

    testWidgets('a profile without values asks to set it up', (tester) async {
      profiles = FakeRiderProfileRepository(configured: true);
      await pumpProfile(tester);
      expect(find.text(t.profileVehicleNotConfigured), findsOneWidget);
    });

    testWidgets('loading shows a skeleton', (tester) async {
      profiles.fetchGate = Completer<void>();
      await pumpScreen(
        tester,
        path: Routes.profile,
        screen: const ProfileScreen(),
        overrides: fakeRepositories(auth, profiles),
        settle: false,
      );
      expect(find.byKey(const Key('skeleton.list')), findsOneWidget);
      profiles.fetchGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('skeleton.list')), findsNothing);
    });

    testWidgets('a load error offers a retry', (tester) async {
      await pumpProfile(tester);
      profiles.fetchError = const NetworkFailure();
      containerOf(tester, ProfileScreen).invalidate(riderProfileProvider);
      await tester.pumpAndSettle();
      expect(find.text(t.failureNetwork), findsOneWidget);

      profiles.fetchError = null;
      await scrollIntoView(tester, find.text(t.commonRetry));
      await tester.tap(find.text(t.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text(t.failureNetwork), findsNothing);
      expect(find.text('Asia/Bangkok'), findsOneWidget);
    });

    for (final (key, route) in [
      ('profile.displayName', Routes.profileDisplayName),
      ('profile.vehicle', Routes.riderProfile),
      ('profile.timezone', Routes.riderProfile),
      ('profile.about', Routes.about),
      ('profile.deleteAccount', Routes.deleteAccount),
    ]) {
      testWidgets('$key opens $route', (tester) async {
        await pumpProfile(tester);
        await scrollAndTap(tester, key);
        expect(find.text('route:$route'), findsOneWidget);
      });
    }

    testWidgets('logout ends the session', (tester) async {
      await pumpProfile(tester);
      await scrollAndTap(tester, 'profile.logout');
      expect(auth.calls, contains('logout'));
    });

    test('vehicle summary leaves out empty values', () {
      expect(vehicleSummary(t, const RiderProfile()), isNull);
      expect(
        vehicleSummary(t, RiderProfile(fuelKmPerLiter: Decimal.fromInt(40))),
        '40 กม./ลิตร',
      );
    });
  });

  group('display name', () {
    /// The screen is only reachable when signed in: restore the session first.
    Future<void> pumpForm(WidgetTester tester) async {
      final router = await pumpScreen(
        tester,
        path: Routes.profileDisplayName,
        screen: const DisplayNameScreen(),
        overrides: fakeRepositories(auth, profiles),
        initialLocation: Routes.home,
      );
      containerOf(
        tester,
        Scaffold,
      ).listen(sessionControllerProvider, (_, _) {});
      await tester.pumpAndSettle();
      unawaited(router.push(Routes.profileDisplayName));
      await tester.pumpAndSettle();
    }

    testWidgets('starts with the current name and saves the trimmed one', (
      tester,
    ) async {
      await pumpForm(tester);
      expect(find.text(testUser.displayName), findsOneWidget);
      await enter(tester, 'displayName.field', '  Somsak  ');
      await tapKey(tester, 'displayName.submit');
      expect(auth.lastArgs['displayName'], 'Somsak');
      expect(find.text('route:${Routes.home}'), findsOneWidget);
      expect(find.text(t.recordSaved), findsOneWidget);
      final session = containerOf(
        tester,
        Scaffold,
      ).read(sessionControllerProvider) as SignedIn;
      expect(session.user.displayName, 'Somsak');
    });

    testWidgets('validation: required and at most 80 characters', (
      tester,
    ) async {
      await pumpForm(tester);
      await enter(tester, 'displayName.field', '   ');
      await tapKey(tester, 'displayName.submit');
      expect(find.text(t.validationRequired), findsOneWidget);
      await enter(tester, 'displayName.field', 'ก' * 81);
      // The field stops at 80 characters, like the API.
      expect(find.text('ก' * 80), findsOneWidget);
      expect(auth.calls, isNot(contains('updateName')));
    });

    testWidgets('a server error is a banner above the button', (tester) async {
      auth.updateNameError = const NetworkFailure();
      await pumpForm(tester);
      await enter(tester, 'displayName.field', 'Somsak');
      await tapKey(tester, 'displayName.submit');
      expect(find.text(t.failureNetwork), findsOneWidget);
      expect(find.byType(DisplayNameScreen), findsOneWidget);
    });
  });

  group('rider profile form', () {
    Future<void> pumpForm(WidgetTester tester) async {
      await pushScreen(
        tester,
        pattern: Routes.riderProfile,
        location: Routes.riderProfile,
        screen: const RiderProfileFormScreen(),
        overrides: fakeRepositories(auth, profiles),
      );
    }

    testWidgets('starts with the saved values and sends the whole profile', (
      tester,
    ) async {
      await pumpForm(tester);
      expect(find.text('45.5'), findsOneWidget);
      expect(find.text('38.5'), findsOneWidget);
      expect(find.text('0.125'), findsOneWidget);
      expect(find.text('Asia/Bangkok'), findsOneWidget);
      final container = containerOf(tester, RiderProfileFormScreen);
      final revision = container.read(profitDataRevisionProvider);

      await enter(tester, 'riderProfile.fuelPrice', '40');
      await enter(tester, 'riderProfile.timezone', ' Asia/Ho_Chi_Minh ');
      await tapKey(tester, 'riderProfile.submit');

      expect(
        profiles.lastSaved,
        RiderProfileInput(
          vehicleType: VehicleType.motorcycle,
          fuelKmPerLiter: Decimal.parse('45.5'),
          fuelPricePerLiter: Decimal.fromInt(40),
          depreciationPerKm: Decimal.parse('0.125'),
          timezone: 'Asia/Ho_Chi_Minh',
        ),
      );
      expect(find.text('route:${Routes.home}'), findsOneWidget);
      // The zone decides TrueProfit days and weeks: the summaries reload.
      expect(container.read(profitDataRevisionProvider), revision + 1);
    });

    testWidgets('clearing a value sends null', (tester) async {
      await pumpForm(tester);
      await enter(tester, 'riderProfile.depreciation', '');
      await tapKey(tester, 'riderProfile.submit');
      expect(profiles.lastSaved?.depreciationPerKm, isNull);
    });

    testWidgets('daily goal: starts with the saved goal, sent or cleared', (
      tester,
    ) async {
      profiles = FakeRiderProfileRepository(
        configured: true,
        profile: _configured.copyWith(dailyGoal: Decimal.parse('600')),
      );
      await pumpForm(tester);
      expect(find.text('600'), findsOneWidget);

      await enter(tester, 'riderProfile.dailyGoal', '750.5');
      await tapKey(tester, 'riderProfile.submit');
      expect(profiles.lastSaved?.dailyGoal, Decimal.parse('750.5'));
      // The other fields go back unchanged.
      expect(profiles.lastSaved?.fuelKmPerLiter, Decimal.parse('45.5'));
    });

    testWidgets('daily goal: empty sends null, zero is refused', (
      tester,
    ) async {
      await pumpForm(tester);
      await enter(tester, 'riderProfile.dailyGoal', '0');
      await tapKey(tester, 'riderProfile.submit');
      expect(find.text(t.validationNumberMustBePositive), findsOneWidget);
      expect(profiles.saves, 0);

      await enter(tester, 'riderProfile.dailyGoal', '');
      await tapKey(tester, 'riderProfile.submit');
      expect(profiles.saves, 1);
      expect(profiles.lastSaved?.dailyGoal, isNull);
    });

    testWidgets('validation runs before saving', (tester) async {
      await pumpForm(tester);
      await enter(tester, 'riderProfile.fuelKmPerLiter', '0');
      await enter(tester, 'riderProfile.timezone', '');
      await tapKey(tester, 'riderProfile.submit');
      expect(find.text(t.validationNumberMustBePositive), findsOneWidget);
      expect(find.text(t.validationRequired), findsOneWidget);
      expect(profiles.saves, 0);
    });

    testWidgets('an unknown zone from the server is explained', (tester) async {
      profiles.saveError = const ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.invalidTimezone,
      );
      await pumpForm(tester);
      await enter(tester, 'riderProfile.timezone', 'Mars/Base');
      await tapKey(tester, 'riderProfile.submit');
      expect(find.text(t.failureInvalidTimezone), findsOneWidget);
      expect(find.byType(RiderProfileFormScreen), findsOneWidget);
    });

    testWidgets('a load error offers a retry', (tester) async {
      profiles.fetchError = const NetworkFailure();
      await pumpForm(tester);
      expect(find.text(t.failureNetwork), findsOneWidget);
      profiles.fetchError = null;
      await tester.tap(find.text(t.commonRetry));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('riderProfile.submit')), findsOneWidget);
    });
  });

  group('delete account', () {
    Future<void> pumpForm(WidgetTester tester) async {
      await pushScreen(
        tester,
        pattern: Routes.deleteAccount,
        location: Routes.deleteAccount,
        screen: const DeleteAccountScreen(),
        overrides: fakeRepositories(auth, profiles),
      );
    }

    testWidgets('warns that everything is deleted for good', (tester) async {
      await pumpForm(tester);
      expect(find.text(t.deleteAccountWarning), findsOneWidget);
      expect(find.text(t.deleteAccountIrreversible), findsOneWidget);
    });

    testWidgets('the password is required', (tester) async {
      await pumpForm(tester);
      await tapKey(tester, 'deleteAccount.submit');
      expect(find.text(t.validationRequired), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cancelling the dialog deletes nothing', (tester) async {
      await pumpForm(tester);
      await enter(tester, 'deleteAccount.password', 'secret pw');
      await tapKey(tester, 'deleteAccount.submit');
      expect(find.text(t.deleteAccountConfirmTitle), findsOneWidget);
      await tapKey(tester, 'confirm.cancel');
      expect(auth.calls, isNot(contains('deleteAccount')));
    });

    testWidgets('confirming deletes and signs out', (tester) async {
      auth.deleteGate = Completer<void>();
      await pumpForm(tester);
      await enter(tester, 'deleteAccount.password', 'secret pw');
      await tapKey(tester, 'deleteAccount.submit');
      await tapKey(tester, 'confirm.delete', settle: false);
      await tester.pump();
      // Spinner while the request runs; a second tap does nothing.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      auth.deleteGate!.complete();
      await tester.pumpAndSettle();
      expect(auth.lastArgs['password'], 'secret pw');
      final container = containerOf(tester, Scaffold);
      expect(
        container.read(sessionControllerProvider),
        isA<SignedOut>().having(
          (s) => s.reason,
          'reason',
          SignOutReason.accountDeleted,
        ),
      );
    });

    testWidgets('a wrong password is explained', (tester) async {
      auth.deleteError = const ApiFailure(
        statusCode: 403,
        code: ApiErrorCode.invalidPassword,
      );
      await pumpForm(tester);
      await enter(tester, 'deleteAccount.password', 'wrong');
      await tapKey(tester, 'deleteAccount.submit');
      await tapKey(tester, 'confirm.delete');
      expect(find.text(t.failureInvalidPassword), findsOneWidget);
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
    });
  });

  group('about', () {
    testWidgets('shows the data licence and the required acknowledgement', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        path: Routes.about,
        screen: const AboutScreen(),
        overrides: fakeRepositories(auth, profiles),
      );
      expect(
        find.text('This research was supported by data provided by Meituan.'),
        findsOneWidget,
      );
      expect(find.textContaining('CC BY-NC 4.0'), findsOneWidget);
      await tapKey(tester, 'about.licenses');
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
