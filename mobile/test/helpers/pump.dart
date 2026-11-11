import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/app/theme/app_theme.dart';
import 'package:rideros_ai/core/utils/clock.dart';
import 'package:rideros_ai/features/auth/data/auth_repository_impl.dart';
import 'package:rideros_ai/features/pickup/data/pickup_repository_impl.dart';
import 'package:rideros_ai/features/profile/data/rider_profile_repository_impl.dart';
import 'package:rideros_ai/features/profit/data/profit_repositories_impl.dart';
import 'package:rideros_ai/l10n/app_localizations.dart';
import 'package:rideros_ai/l10n/app_localizations_th.dart';

import 'fakes.dart';
import 'pickup_fakes.dart';
import 'profit_fakes.dart';

/// Overrides that replace the network layer with fakes and fix "now" to [testNow].
List<Override> fakeRepositories(
  FakeAuthRepository auth, [
  FakeRiderProfileRepository? profiles,
  ProfitFakes? profit,
  FakePickupRepository? pickup,
]) {
  final p = profit ?? ProfitFakes();
  return [
    pickupRepositoryProvider.overrideWithValue(
      pickup ?? FakePickupRepository(),
    ),
    authRepositoryProvider.overrideWithValue(auth),
    riderProfileRepositoryProvider.overrideWithValue(
      profiles ?? FakeRiderProfileRepository(),
    ),
    profitRepositoryProvider.overrideWithValue(p.profit),
    incomeRepositoryProvider.overrideWithValue(p.income),
    expenseRepositoryProvider.overrideWithValue(p.expenses),
    workSessionRepositoryProvider.overrideWithValue(p.sessions),
    clockProvider.overrideWithValue(testNow),
  ];
}

/// Every route pattern of the app (for the placeholder routes of [pumpScreen]).
const allRoutePatterns = [
  ...Routes.public,
  Routes.splash,
  Routes.onboarding,
  Routes.home,
  Routes.profit,
  Routes.pickup,
  Routes.restaurantPattern,
  Routes.predictionPattern,
  Routes.predictionHistory,
  Routes.pickupLogs,
  Routes.pickupLogNew,
  Routes.ownRestaurantNew,
  Routes.restaurantPicker,
  Routes.modelInfo,
  Routes.records,
  Routes.incomeNew,
  Routes.incomeEditPattern,
  Routes.expenseNew,
  Routes.expenseEditPattern,
  Routes.workSessionNew,
  Routes.workSessionEditPattern,
  Routes.profile,
  Routes.profileDisplayName,
  Routes.riderProfile,
  Routes.deleteAccount,
  Routes.about,
];

/// Pumps one screen at [path] inside a router. Every other route renders
/// `Text('route:<path>')` so tests can assert where a button navigated to.
/// Returns the router so a test can push the screen over another route.
Future<GoRouter> pumpScreen(
  WidgetTester tester, {
  required String path,
  required Widget screen,
  required List<Override> overrides,
  String? initialLocation,
  bool settle = true,
}) async {
  final otherRoutes = allRoutePatterns.where((p) => p != path);
  final router = GoRouter(
    initialLocation: initialLocation ?? path,
    routes: [
      GoRoute(path: path, builder: (context, state) => screen),
      for (final other in otherRoutes)
        GoRoute(
          path: other,
          builder: (context, state) =>
              Scaffold(body: Text('route:${state.uri}')),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (retryCount, error) => null,
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('th'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

/// Pumps [screen] pushed over the home placeholder, so it can pop back
/// (`route:/home` is visible afterwards).
Future<GoRouter> pushScreen(
  WidgetTester tester, {
  required String pattern,
  required String location,
  required Widget screen,
  required List<Override> overrides,
}) async {
  final router = await pumpScreen(
    tester,
    path: pattern,
    screen: screen,
    overrides: overrides,
    initialLocation: Routes.home,
  );
  unawaited(router.push(location));
  await tester.pumpAndSettle();
  return router;
}

/// Types into the text field with [key].
Future<void> enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

/// Scrolls to and taps the widget with [key], then settles.
Future<void> tapKey(
  WidgetTester tester,
  String key, {
  bool settle = true,
}) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Scrolls the first scrollable until [finder] is built and fully on screen. Needed
/// for rows of lazily built lists that start below the 800x600 test screen.
Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
}

/// [scrollIntoView] then [tapKey].
Future<void> scrollAndTap(WidgetTester tester, String key) async {
  await scrollIntoView(tester, find.byKey(Key(key)));
  await tapKey(tester, key);
}

/// Thai strings for assertions.
final t = AppLocalizationsTh();
