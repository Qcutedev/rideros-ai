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
  static const pickup = '/pickup';

  static const profile = '/profile';

  /// TrueProfit records: `?tab=` one of [RecordsTab] names.
  static const records = '/profit/records';

  // Pickup screens inside the Pickup tab.
  static const restaurantPattern = '/pickup/restaurants/:id';
  static const predictionPattern = '/pickup/restaurants/:id/prediction';
  static const predictionHistory = '/pickup/predictions';
  static const pickupLogs = '/pickup/logs';

  // Pickup forms and pages, shown over the tabs.
  static const pickupLogNew = '/pickup/logs/new';
  static const ownRestaurantNew = '/pickup/own-restaurant';
  static const restaurantPicker = '/pickup/select-restaurant';
  static const modelInfo = '/pickup/model';

  static String restaurant(String id) => '/pickup/restaurants/$id';
  static String prediction(String id) => '/pickup/restaurants/$id/prediction';

  /// The log form, optionally with the restaurant already chosen.
  static String pickupLogNewFor({String? restaurantId, String? name}) => Uri(
    path: pickupLogNew,
    queryParameters: restaurantId == null
        ? null
        : {'restaurant_id': restaurantId, 'restaurant_name': ?name},
  ).toString();

  // Profile screens, shown over the tabs.
  static const profileDisplayName = '/profile/display-name';
  static const riderProfile = '/profile/rider';
  static const deleteAccount = '/profile/delete-account';
  static const about = '/profile/about';

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
