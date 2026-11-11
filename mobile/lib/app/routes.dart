/// Route paths. Kept apart from `router.dart` so screens can navigate without
/// importing the router (which imports every screen).
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const onboarding = '/onboarding';

  // Bottom-navigation tabs (signed in).
  static const home = '/home';
  static const profit = '/profit';

  /// TrueProfit records: `?tab=` one of [RecordsTab] names.
  static const records = '/profit/records';

  // Record forms, shown over the tabs.
  static const incomeNew = '/income/new';
  static const incomeEditPattern = '/income/:id';
  static const expenseNew = '/expenses/new';
  static const expenseEditPattern = '/expenses/:id';
  static const workSessionNew = '/work-sessions/new';
  static const workSessionEditPattern = '/work-sessions/:id';

  static String incomeEdit(String id) => '/income/$id';
  static String expenseEdit(String id) => '/expenses/$id';
  static String workSessionEdit(String id) => '/work-sessions/$id';
  static String recordsTab(RecordsTab tab) => '$records?tab=${tab.name}';

  /// Screens reachable without a session.
  static const public = {login, register, forgotPassword, resetPassword};
}

enum RecordsTab { income, expenses, sessions }

/// `?notice=` values the login screen turns into a banner.
abstract final class LoginNotice {
  static const registered = 'registered';
  static const passwordReset = 'password_reset';
}
