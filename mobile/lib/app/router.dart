import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/session_state.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/pickup/presentation/model_info_screen.dart';
import '../features/pickup/presentation/own_restaurant_form_screen.dart';
import '../features/pickup/presentation/pickup_log_form_screen.dart';
import '../features/pickup/presentation/pickup_logs_screen.dart';
import '../features/pickup/presentation/pickup_search_screen.dart';
import '../features/pickup/presentation/prediction_history_screen.dart';
import '../features/pickup/presentation/prediction_result_screen.dart';
import '../features/pickup/presentation/restaurant_screen.dart';
import '../features/profile/presentation/about_screen.dart';
import '../features/profile/presentation/delete_account_screen.dart';
import '../features/profile/presentation/display_name_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/rider_profile_form_screen.dart';
import '../features/profit/presentation/expense_form_screen.dart';
import '../features/profit/presentation/income_form_screen.dart';
import '../features/profit/presentation/records_screen.dart';
import '../features/profit/presentation/true_profit_screen.dart';
import '../features/profit/presentation/work_session_form_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

export 'routes.dart';

/// The auth guard. Pure so it can be tested as a table.
///
/// * restoring / restore failed → splash
/// * signed out → public screens only (default: login)
/// * signed in without a rider profile → onboarding
/// * signed in → anything but public screens, splash and onboarding (default: home)
String? authRedirect(SessionState session, Uri location) {
  final path = location.path;
  final isPublic = Routes.public.contains(path);
  switch (session) {
    case SessionRestoring() || SessionRestoreFailed():
      return path == Routes.splash ? null : Routes.splash;
    case SignedOut():
      return isPublic ? null : Routes.login;
    case SignedIn(profileConfigured: false):
      return path == Routes.onboarding ? null : Routes.onboarding;
    case SignedIn():
      final leave =
          isPublic || path == Routes.splash || path == Routes.onboarding;
      return leave ? Routes.home : null;
  }
}

/// What [authRedirect] depends on. Other changes (e.g. a new display name) must not
/// refresh the router: a refresh re-applies the current location and would undo a
/// `pop` that happens right after the change.
Object _guardKey(SessionState session) => switch (session) {
  SessionRestoring() => 'restoring',
  SessionRestoreFailed() => 'restore_failed',
  SignedOut() => 'signed_out',
  SignedIn(:final profileConfigured) => ('signed_in', profileConfigured),
};

/// Router refresh signal: holds the latest session, notifies only when the guard's
/// answer can change.
class _GuardRefresh extends ChangeNotifier {
  _GuardRefresh(this.state);

  SessionState state;

  void update(SessionState next) {
    final changed = _guardKey(state) != _guardKey(next);
    state = next;
    if (changed) notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Root navigator: record forms open over the bottom navigation.
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final session = _GuardRefresh(ref.read(sessionControllerProvider));
  ref.listen(sessionControllerProvider, (_, next) => session.update(next));

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (context, state) => authRedirect(session.state, state.uri),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) =>
            LoginScreen(notice: state.uri.queryParameters['notice']),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.pickup,
                builder: (context, state) => const PickupSearchScreen(),
                routes: [
                  GoRoute(
                    path: 'restaurants/:id',
                    builder: (context, state) =>
                        RestaurantScreen(id: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'prediction',
                        builder: (context, state) => PredictionResultScreen(
                          restaurantId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'predictions',
                    builder: (context, state) =>
                        const PredictionHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'logs',
                    builder: (context, state) => const PickupLogsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profit,
                builder: (context, state) => const TrueProfitScreen(),
                routes: [
                  GoRoute(
                    path: 'records',
                    builder: (context, state) => RecordsScreen(
                      initialTab:
                          RecordsTab.values
                              .asNameMap()[state.uri.queryParameters['tab']] ??
                          RecordsTab.income,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      ...formRoutes(rootKey),
      ...pickupRoutes(rootKey),
      ...profileRoutes(rootKey),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});

/// Record forms on the [root] navigator. `new` is listed before `:id` so it is never
/// read as an id.
List<GoRoute> formRoutes(GlobalKey<NavigatorState> root) => [
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.incomeNew,
    builder: (context, state) => const IncomeFormScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.incomeEditPattern,
    builder: (context, state) =>
        IncomeFormScreen(id: state.pathParameters['id']),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.expenseNew,
    builder: (context, state) => const ExpenseFormScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.expenseEditPattern,
    builder: (context, state) =>
        ExpenseFormScreen(id: state.pathParameters['id']),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.workSessionNew,
    builder: (context, state) => const WorkSessionFormScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.workSessionEditPattern,
    builder: (context, state) =>
        WorkSessionFormScreen(id: state.pathParameters['id']),
  ),
];

/// Pickup forms and pages on the [root] navigator (they cover the tabs). The model
/// card is here so the Profile tab can open it too.
List<GoRoute> pickupRoutes(GlobalKey<NavigatorState> root) => [
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.pickupLogNew,
    builder: (context, state) {
      final id = state.uri.queryParameters['restaurant_id'];
      final name = state.uri.queryParameters['restaurant_name'];
      return PickupLogFormScreen(
        restaurant: id == null ? null : (id: id, name: name ?? id),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.ownRestaurantNew,
    builder: (context, state) => const OwnRestaurantFormScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.restaurantPicker,
    builder: (context, state) =>
        PickupSearchScreen(onSelect: (restaurant) => context.pop(restaurant)),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.modelInfo,
    builder: (context, state) => const ModelInfoScreen(),
  ),
];

/// Profile forms and pages on the [root] navigator (they cover the tabs).
List<GoRoute> profileRoutes(GlobalKey<NavigatorState> root) => [
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.profileDisplayName,
    builder: (context, state) => const DisplayNameScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.riderProfile,
    builder: (context, state) => const RiderProfileFormScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.deleteAccount,
    builder: (context, state) => const DeleteAccountScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.about,
    builder: (context, state) => const AboutScreen(),
  ),
];
