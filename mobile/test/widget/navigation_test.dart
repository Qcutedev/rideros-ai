import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/app.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/api_client.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';
import 'package:rideros_ai/features/auth/presentation/login_screen.dart';
import 'package:rideros_ai/features/auth/presentation/register_screen.dart';
import 'package:rideros_ai/features/auth/presentation/splash_screen.dart';
import 'package:rideros_ai/features/dashboard/presentation/home_screen.dart';
import 'package:rideros_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/model_info_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/pickup_log_form_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/pickup_logs_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/pickup_search_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/prediction_result_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/restaurant_screen.dart';
import 'package:rideros_ai/features/profile/presentation/delete_account_screen.dart';
import 'package:rideros_ai/features/profile/presentation/display_name_screen.dart';
import 'package:rideros_ai/features/profile/presentation/profile_screen.dart';
import 'package:rideros_ai/features/profile/presentation/rider_profile_form_screen.dart';
import 'package:rideros_ai/features/profit/presentation/expense_form_screen.dart';
import 'package:rideros_ai/features/profit/presentation/income_form_screen.dart';
import 'package:rideros_ai/features/profit/presentation/records_screen.dart';
import 'package:rideros_ai/features/profit/presentation/true_profit_screen.dart';
import 'package:rideros_ai/features/profit/presentation/work_session_form_screen.dart';
import 'package:rideros_ai/features/shifts/presentation/shift_compare_screen.dart';
import 'package:rideros_ai/features/shifts/presentation/shift_detail_screen.dart';
import 'package:rideros_ai/features/shifts/presentation/shift_form_screen.dart';
import 'package:rideros_ai/features/shifts/presentation/shifts_screen.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/fakes.dart';
import '../helpers/pickup_fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';
import '../helpers/shift_fakes.dart';

/// The real app (router, guard, theme) with fake repositories.
Future<void> pumpApp(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (retryCount, error) => null,
      child: const RiderOsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await enter(tester, 'login.email', 'rider@example.com');
  await enter(tester, 'login.password', 'secret pw');
  await tapKey(tester, 'login.submit');
}

void main() {
  late FakeAuthRepository auth;
  late FakeRiderProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeRiderProfileRepository();
  });

  testWidgets('no stored session: start → login', (tester) async {
    await pumpApp(tester, fakeRepositories(auth, profiles));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('first login → onboarding → home → profile → logout → login', (
    tester,
  ) async {
    await pumpApp(tester, fakeRepositories(auth, profiles));
    await login(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tapKey(tester, 'onboarding.skip');
    expect(find.byType(HomeScreen), findsOneWidget);

    await tapKey(tester, 'nav.profile');
    expect(find.byType(ProfileScreen), findsOneWidget);
    await scrollAndTap(tester, 'profile.logout');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(t.loginSessionExpired), findsNothing);
  });

  testWidgets('configured profile goes straight to home', (tester) async {
    profiles.configured = true;
    await pumpApp(tester, fakeRepositories(auth, profiles));
    await login(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('stored session resumes on home without the login screen', (
    tester,
  ) async {
    auth.restoreUser = testUser;
    profiles.configured = true;
    await pumpApp(tester, fakeRepositories(auth, profiles));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets(
    'register is pushed over login; back returns; success → onboarding',
    (tester) async {
      await pumpApp(tester, fakeRepositories(auth, profiles));
      await tapKey(tester, 'login.register');
      expect(find.byType(RegisterScreen), findsOneWidget);

      await tester.binding.handlePopRoute(); // Android back
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tapKey(tester, 'login.register');
      await enter(tester, 'register.displayName', 'Somchai');
      await enter(tester, 'register.email', 'new@example.com');
      await enter(tester, 'register.password', 'pass word 1');
      await enter(tester, 'register.confirm', 'pass word 1');
      await tapKey(tester, 'register.submit');
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    },
  );

  testWidgets('forgot password → reset → login with notice', (tester) async {
    await pumpApp(tester, fakeRepositories(auth, profiles));
    await tapKey(tester, 'login.forgot');
    await enter(tester, 'forgot.email', 'rider@example.com');
    await tapKey(tester, 'forgot.submit');
    await tapKey(tester, 'forgot.sent.haveToken');
    await enter(
      tester,
      'reset.token',
      'AbCdEf0123456789_-xyz', // gitleaks:allow (fake test token)
    );
    await enter(tester, 'reset.password', 'new pass 123');
    await enter(tester, 'reset.confirm', 'new pass 123');
    await tapKey(tester, 'reset.submit');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(t.loginPasswordResetDone), findsOneWidget);
  });

  testWidgets('session expiring on home returns to login with a banner', (
    tester,
  ) async {
    auth.restoreUser = testUser;
    profiles.configured = true;
    await pumpApp(tester, fakeRepositories(auth, profiles));
    auth.expireSession();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(t.loginSessionExpired), findsOneWidget);
  });

  testWidgets('offline at start: splash error, retry → home', (tester) async {
    auth.restoreError = const NetworkFailure();
    profiles.configured = true;
    await pumpApp(tester, fakeRepositories(auth, profiles));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(t.splashRestoreFailedTitle), findsOneWidget);

    auth
      ..restoreError = null
      ..restoreUser = testUser;
    await tester.tap(find.text(t.commonRetry));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'full stack: real repositories, dio and interceptor against a fake API',
    (tester) async {
      final store = InMemoryRefreshTokenStore();
      var configured = false;
      final adapter = FakeHttpAdapter(
        (o) => switch ((o.method, o.path)) {
          ('POST', '/auth/login') => json(
            200,
            tokenJson(access: 'a1', refresh: 'r1-0000000000000000'),
          ),
          ('GET', '/me') => json(200, userJson()),
          ('GET', '/me/rider-profile') => json(
            200,
            profileJson(configured: configured),
          ),
          ('PUT', '/me/rider-profile') => () {
            configured = true;
            return json(200, profileJson(configured: true));
          }(),
          ('POST', '/auth/logout') => json(204),
          ('GET', '/profit/summary') => json(200, {
            'period': o.queryParameters['period'],
            'start_date': '2026-11-09',
            'end_date': o.queryParameters['period'] == 'day'
                ? '2026-11-09'
                : '2026-11-15',
            'timezone': 'Asia/Bangkok',
            'currency': 'THB',
            'total_revenue': '1200.00',
            'total_expenses': '150.50',
            'net_profit': '1049.50',
            'working_hours': '0.00',
            'revenue_per_hour': null,
            'net_profit_per_hour': null,
            'reason': 'no_working_hours',
            'income_count': 2,
            'expense_count': 1,
            'work_session_count': 0,
          }),
          _ => apiError(404, 'not_found'),
        },
      );
      await pumpApp(tester, [
        refreshTokenStoreProvider.overrideWithValue(store),
        baseDioProvider.overrideWith(
          (ref) =>
              Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
                ..httpClientAdapter = adapter,
        ),
      ]);
      expect(find.byType(LoginScreen), findsOneWidget);

      await login(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(store.value, 'r1-0000000000000000');

      await enter(tester, 'onboarding.fuelPrice', '38.50');
      await tapKey(tester, 'onboarding.submit');
      expect(find.byType(HomeScreen), findsOneWidget);
      final put = adapter.requests.firstWhere((r) => r.method == 'PUT');
      expect((put.data as Map)['fuel_price_per_liter'], '38.5');
      expect(put.headers['Authorization'], 'Bearer a1');
      // Home numbers come from the real summary endpoint (decimal strings).
      expect(find.text('฿1,049.50'), findsNWidgets(2));
      expect(adapter.count('/profit/summary'), 2);

      await tapKey(tester, 'nav.profile');
      await scrollAndTap(tester, 'profile.logout');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(store.value, isNull);
      expect(adapter.paths.last, '/auth/logout');
    },
  );

  group('signed in', () {
    late ProfitFakes profit;

    setUp(() {
      auth.restoreUser = testUser;
      profiles.configured = true;
      profit = ProfitFakes();
    });

    testWidgets('tabs → records → add income over the tabs → back to list', (
      tester,
    ) async {
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tapKey(tester, 'nav.profit');
      expect(find.byType(TrueProfitScreen), findsOneWidget);

      await tapKey(tester, 'profit.records');
      expect(find.byType(RecordsScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tapKey(tester, 'records.add');
      expect(find.byType(IncomeFormScreen), findsOneWidget);
      // Forms cover the bottom navigation.
      expect(find.byType(NavigationBar), findsNothing);

      await enter(tester, 'income.amount', '450');
      await tapKey(tester, 'income.submit');
      expect(find.byType(RecordsScreen), findsOneWidget);
      expect(find.text('450.00'), findsOneWidget);

      // Home keeps its own stack and reloaded its numbers after the save.
      await tapKey(tester, 'nav.home');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        profit.profit.calls.where((c) => c == 'summary:day:-').length,
        greaterThanOrEqualTo(2),
      );
      await tapKey(tester, 'nav.profit');
      expect(find.byType(RecordsScreen), findsOneWidget);
      // Tapping the open tab again returns to its first screen.
      await tapKey(tester, 'nav.profit');
      expect(find.byType(TrueProfitScreen), findsOneWidget);
    });

    testWidgets('home shortcut → expense form → back without saving', (
      tester,
    ) async {
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'home.addExpense');
      expect(find.byType(ExpenseFormScreen), findsOneWidget);
      await tester.binding.handlePopRoute(); // Android back
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(profit.expenses.calls, isEmpty);
    });

    testWidgets('tabs in order: home, pickup, profit, shifts, profile', (
      tester,
    ) async {
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      final xs = [
        for (final key in [
          'nav.home',
          'nav.pickup',
          'nav.profit',
          'nav.shifts',
          'nav.profile',
        ])
          tester.getCenter(find.byKey(Key(key))).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
    });

    testWidgets('pickup: search → restaurant → prediction → log saved', (
      tester,
    ) async {
      final pickup = FakePickupRepository();
      await pumpApp(tester, fakeRepositories(auth, profiles, profit, pickup));
      await tapKey(tester, 'nav.pickup');
      expect(find.byType(PickupSearchScreen), findsOneWidget);

      await tapKey(tester, 'restaurant.r-1');
      expect(find.byType(RestaurantScreen), findsOneWidget);
      // Details stay inside the tab.
      expect(find.byType(NavigationBar), findsOneWidget);

      await tapKey(tester, 'restaurant.predict');
      expect(find.byType(PredictionResultScreen), findsOneWidget);
      expect(pickup.calls, contains('predict:r-1'));

      await scrollAndTap(tester, 'prediction.log');
      expect(find.byType(PickupLogFormScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('POI-1'), findsOneWidget);
      await tapKey(tester, 'logForm.submit');
      expect(find.byType(PredictionResultScreen), findsOneWidget);
      expect(pickup.lastLog!.restaurantId, 'r-1');

      // Back to the restaurant, back to the search.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RestaurantScreen), findsOneWidget);
    });

    testWidgets('pickup: logs → new log → picker → saved in the list', (
      tester,
    ) async {
      final pickup = FakePickupRepository();
      await pumpApp(tester, fakeRepositories(auth, profiles, profit, pickup));
      await tapKey(tester, 'nav.pickup');
      await tapKey(tester, 'pickup.logs');
      expect(find.byType(PickupLogsScreen), findsOneWidget);
      await tapKey(tester, 'logs.add');
      expect(find.byType(PickupLogFormScreen), findsOneWidget);

      await tapKey(tester, 'logForm.restaurant');
      expect(find.text(t.pickerTitle), findsOneWidget);
      await tapKey(tester, 'restaurant.r-2');
      expect(find.byType(PickupLogFormScreen), findsOneWidget);
      expect(find.text('POI-2'), findsOneWidget);

      await tapKey(tester, 'logForm.submit');
      expect(find.byType(PickupLogsScreen), findsOneWidget);
      expect(pickup.lastLog!.restaurantId, 'r-2');
      expect(
        find.byKey(Key('log.${pickup.logItems.single.id}')),
        findsOneWidget,
      );
    });

    testWidgets('shifts: new over the tabs → details in the tab → compare', (
      tester,
    ) async {
      final shifts = FakeShiftRepository(items: [scenario(id: 'old')]);
      await pumpApp(
        tester,
        fakeRepositories(auth, profiles, profit, null, shifts),
      );
      await tapKey(tester, 'nav.shifts');
      expect(find.byType(ShiftsScreen), findsOneWidget);

      await tapKey(tester, 'shifts.add');
      expect(find.byType(ShiftFormScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await enter(tester, 'shiftForm.name', 'Night');
      await enter(tester, 'shiftForm.ordersPerHour', '2');
      await enter(tester, 'shiftForm.incomePerOrder', '50');
      await tapKey(tester, 'shiftForm.submit');

      // The new scenario's details, inside the tab; back = the list.
      expect(find.byType(ShiftDetailScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('shift.net'))).data,
        '฿500.00',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ShiftsScreen), findsOneWidget);

      await tapKey(tester, 'shift.new-1.select');
      await tapKey(tester, 'shift.old.select');
      await tapKey(tester, 'shifts.compare');
      expect(find.byType(ShiftCompareScreen), findsOneWidget);
      expect(shifts.calls, contains('compare:new-1,old'));

      // Deleting from the details drops it from the selection.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tapKey(tester, 'shift.old');
      await tapKey(tester, 'shift.delete');
      await tapKey(tester, 'confirm.delete');
      expect(find.byType(ShiftsScreen), findsOneWidget);
      expect(find.text(t.shiftsSelectedCount(1)), findsOneWidget);
      expect(find.byKey(const Key('shifts.compare')), findsNothing);
    });

    testWidgets('profile → Pickup model card over the tabs → back', (
      tester,
    ) async {
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'nav.profile');
      await scrollAndTap(tester, 'profile.modelInfo');
      expect(find.byType(ModelInfoScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('home shortcut → work session saved → home', (tester) async {
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'home.addSession');
      expect(find.byType(WorkSessionFormScreen), findsOneWidget);
      await tapKey(tester, 'session.submit');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(profit.sessions.items, hasLength(1));
    });

    testWidgets('the guard keeps signed-out users out of record forms', (
      tester,
    ) async {
      auth.restoreUser = null;
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      final router = ProviderScope.containerOf(
        tester.element(find.byType(LoginScreen)),
      ).read(routerProvider);
      router.go(Routes.incomeNew);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(IncomeFormScreen), findsNothing);
    });

    testWidgets('profile tab → rider profile form → saved → profile', (
      tester,
    ) async {
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'nav.profile');
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(t.profileVehicleNotConfigured), findsOneWidget);

      await tapKey(tester, 'profile.vehicle');
      expect(find.byType(RiderProfileFormScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await enter(tester, 'riderProfile.fuelKmPerLiter', '40');
      await tapKey(tester, 'riderProfile.submit');

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('40 กม./ลิตร'), findsOneWidget);
    });

    testWidgets('delete account → login with a notice', (tester) async {
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'nav.profile');
      await scrollAndTap(tester, 'profile.deleteAccount');
      expect(find.byType(DeleteAccountScreen), findsOneWidget);

      await enter(tester, 'deleteAccount.password', 'secret pw');
      await tapKey(tester, 'deleteAccount.submit');
      await tapKey(tester, 'confirm.delete');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(t.loginAccountDeleted), findsOneWidget);
      expect(auth.calls, contains('deleteAccount'));
    });

    // Regression: the new name updates the session; that must not refresh the router
    // and undo the pop back to the profile tab.
    testWidgets('rename → back on the profile tab with the new name', (
      tester,
    ) async {
      await pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'nav.profile');
      await tapKey(tester, 'profile.displayName');
      expect(find.byType(DisplayNameScreen), findsOneWidget);
      await enter(tester, 'displayName.field', 'Somsak');
      await tapKey(tester, 'displayName.submit');
      expect(find.byType(DisplayNameScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Somsak'), findsWidgets);
    });
  });
}
