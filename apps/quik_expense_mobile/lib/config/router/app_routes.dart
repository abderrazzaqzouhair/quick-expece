/// Centralized path constants — screens reference these, never a raw string.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const verifyResetCode = '/forgot-password/code';
  static const resetPassword = '/forgot-password/reset';

  // Bottom-nav tabs.
  static const home = '/home';
  static const statistics = '/statistics';
  static const history = '/history';
  static const profile = '/profile';

  // Reachable, but not one of the 5 bottom-nav slots.
  static const categories = '/categories';
  static const addExpense = '/add-expense';
  static const expenses = '/expenses';

  // Profile sub-screens (pushed full-screen over the tabs).
  static const profileEdit = '/profile/edit';
  static const profileCategories = '/profile/categories';
  static String profileSubcategories(String categoryId) =>
      '/profile/categories/$categoryId';
  static const profileSettings = '/profile/settings';
  static const profileSupport = '/profile/support';
  static const profilePrivacy = '/profile/privacy';
  static const profileAbout = '/profile/about';
}
