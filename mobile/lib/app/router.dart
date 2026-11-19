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
import '../features/profile/presentation/about_screen.dart';
import '../features/profile/presentation/delete_account_screen.dart';
import '../features/profile/presentation/display_name_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/rider_profile_form_screen.dart';
import '../features/profit/domain/profit_records.dart';
import '../features/profit/domain/shift_timer.dart';
import '../features/profit/presentation/expense_form_screen.dart';
import '../features/profit/presentation/income_form_screen.dart';
import '../features/profit/presentation/records_screen.dart';
import '../features/profit/presentation/true_profit_screen.dart';
import '../features/profit/presentation/work_session_form_screen.dart';
import '../features/road/domain/road_models.dart';
import '../features/road/presentation/incident_detail_screen.dart';
import '../features/road/presentation/location_picker_screen.dart';
import '../features/road/presentation/my_reports_screen.dart';
import '../features/road/presentation/report_form_screen.dart';
import '../features/road/presentation/road_screen.dart';
import '../features/shifts/presentation/shift_compare_screen.dart';
import '../features/shifts/presentation/shift_detail_screen.dart';
import '../features/shifts/presentation/shift_form_screen.dart';
import '../features/shifts/presentation/shifts_screen.dart';
import '../features/shifts/presentation/work_session_picker_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

export 'routes.dart';

/// The auth guard. Pure so it can be tested as a table.
///
/// * restoring / restore failed → splash
/// * signed out → public screens only (default: login)
/// * signed in without a rider profile → onboarding
/// * signed in → anything but public screens, splash and onboarding (default: home)
/// * a password reset link opens the reset screen in every state but restoring
String? authRedirect(SessionState session, Uri location) {
  final path = location.path;
  final isPublic = Routes.public.contains(path);
  switch (session) {
    case SessionRestoring() || SessionRestoreFailed():
      return path == Routes.splash ? null : Routes.splash;
    case SignedOut():
      return isPublic ? null : Routes.login;
    case SignedIn() when path == Routes.resetPassword:
      // The e-mail link must not be lost because the rider is signed in.
      return null;
    case SignedIn(profileConfigured: false):
      return path == Routes.onboarding ? null : Routes.onboarding;
    case SignedIn():
      final leave =
          isPublic || path == Routes.splash || path == Routes.onboarding;
      return leave ? Routes.home : null;
  }
}

/// The password reset e-mail link (`rideros://reset-password?token=…`, backend
/// `PASSWORD_RESET_URL_BASE`) as an app location, or null for any other URI.
/// Android hands the whole link to the router, whose path is empty.
Uri? resetLinkLocation(Uri uri) {
  if (uri.scheme != 'rideros' || uri.host != 'reset-password') return null;
  final token = uri.queryParameters['token'];
  return Uri(
    path: Routes.resetPassword,
    queryParameters: token == null ? null : {'token': token},
  );
}

/// Top-level redirect: maps the reset link, keeps it while the session is
/// being restored (the guard shows splash meanwhile), then applies the guard.
class AppRedirect {
  Uri? _pendingLink;

  String? call(SessionState session, Uri uri) {
    final link = resetLinkLocation(uri);
    final restoring =
        session is SessionRestoring || session is SessionRestoreFailed;
    if (restoring) {
      if (link != null) _pendingLink = link;
      return authRedirect(session, uri);
    }
    final target = link ?? _pendingLink ?? uri;
    _pendingLink = null;
    final guarded = authRedirect(session, target);
    if (guarded != null) return guarded;
    return identical(target, uri) ? null : target.toString();
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
  final redirect = AppRedirect();

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (context, state) => redirect(session.state, state.uri),
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
                path: Routes.road,
                builder: (context, state) => const RoadScreen(),
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
                path: Routes.shifts,
                builder: (context, state) => const ShiftsScreen(),
                routes: [
                  GoRoute(
                    path: 'compare',
                    builder: (context, state) => ShiftCompareScreen(
                      ids: state.uri.queryParameters['ids'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'scenarios/:id',
                    builder: (context, state) =>
                        ShiftDetailScreen(id: state.pathParameters['id']!),
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
      ...shiftRoutes(rootKey),
      ...profileRoutes(rootKey),
      ...roadRoutes(rootKey),
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
    // `extra`: the work session the Home timer just saved (in-app only).
    builder: (context, state) =>
        IncomeFormScreen(forSession: state.extra as WorkSession?),
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
    // `extra`: start and end from the Home timer (in-app navigation only).
    builder: (context, state) =>
        WorkSessionFormScreen(draft: state.extra as SessionDraft?),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.workSessionEditPattern,
    builder: (context, state) =>
        WorkSessionFormScreen(id: state.pathParameters['id']),
  ),
];

/// Shift forms and the work-session picker on the [root] navigator.
List<GoRoute> shiftRoutes(GlobalKey<NavigatorState> root) => [
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.shiftNew,
    builder: (context, state) => const ShiftFormScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.shiftEditPattern,
    builder: (context, state) =>
        ShiftFormScreen(id: state.pathParameters['id']),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.shiftSessionPicker,
    builder: (context, state) => const WorkSessionPickerScreen(),
  ),
];

/// RoadContext forms and pages on the [root] navigator (the map is the Road
/// tab). The location picker takes the start point as `extra` and pops the
/// chosen one.
List<GoRoute> roadRoutes(GlobalKey<NavigatorState> root) => [
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.roadReportNew,
    builder: (context, state) => const ReportFormScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.roadPickLocation,
    builder: (context, state) =>
        LocationPickerScreen(initial: state.extra as RoadPoint?),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.roadMyReports,
    builder: (context, state) => const MyReportsScreen(),
  ),
  GoRoute(
    parentNavigatorKey: root,
    path: Routes.incidentPattern,
    builder: (context, state) =>
        IncidentDetailScreen(id: state.pathParameters['id']!),
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
