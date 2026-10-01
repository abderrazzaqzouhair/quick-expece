import 'package:core/core.dart';

/// Static endpoint paths grouped by domain, matching `routes/api.php` on the
/// quik-expense-backend Laravel API. Built on [AppConfig.apiBaseUrl].
class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = AppConfig.apiBaseUrl;

  // Auth
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String logoutAll = '/logout-all';
  static const String me = '/me';

  // Categories
  static const String categories = '/categories';
  static const String categoriesAvailable = '/categories/available';
  static String category(int id) => '/categories/$id';

  // Subcategories
  static const String subcategories = '/subcategories';
  static const String subcategoriesAvailable = '/subcategories/available';
  static String subcategory(int id) => '/subcategories/$id';

  // Expenses
  static const String expenses = '/expenses';
  static String expense(int id) => '/expenses/$id';
}
