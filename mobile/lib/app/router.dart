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

final routerProvider = Provider<GoRouter>((ref) {
  // Root navigator: record forms open over the bottom navigation.
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final session = ValueNotifier<SessionState>(
    ref.read(sessionControllerProvider),
  );
  ref.listen(sessionControllerProvider, (_, next) => session.value = next);

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (context, state) => authRedirect(session.value, state.uri),
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
        ],
      ),
      ...formRoutes(rootKey),
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
