import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_expense/add_expense_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/auth/verify_reset_code_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/expense_list/expense_list_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/manage_categories_screen.dart';
import '../../features/profile/screens/manage_subcategories_screen.dart';
import '../../features/profile/screens/privacy_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/support_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../navigation/main_shell.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routes reachable without a valid session — every other route is gated by
/// [_redirect] below. Don't add a route here without also handling what
/// happens if a signed-in user navigates to it directly.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.signIn,
  AppRoutes.signUp,
  AppRoutes.forgotPassword,
  AppRoutes.verifyResetCode,
  AppRoutes.resetPassword,
};

/// Routes a signed-in user shouldn't sit on — redirected to [AppRoutes.home]
/// instead. Splash/reset-code/reset-password aren't included: splash always
/// resolves elsewhere on its own, and the reset flow is a one-shot action
/// with no meaningful "already signed in" state to bounce out of.
const _authOnlyRoutes = {AppRoutes.signIn, AppRoutes.signUp};

String? _redirect(BuildContext context, GoRouterState state) {
  final isSignedIn = TokenService.instance.accessToken != null;
  final isPublicRoute = _publicRoutes.contains(state.matchedLocation);

  if (!isSignedIn && !isPublicRoute) return AppRoutes.signIn;
  if (isSignedIn && _authOnlyRoutes.contains(state.matchedLocation)) {
    return AppRoutes.home;
  }
  return null;
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  redirect: _redirect,
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.verifyResetCode,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => VerifyResetCodeScreen(
        email: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ResetPasswordScreen(
        email: state.uri.queryParameters['email'] ?? '',
        code: state.uri.queryParameters['code'],
      ),
    ),
    GoRoute(
      path: AppRoutes.categories,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: AppRoutes.expenses,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExpenseListScreen(),
    ),
    GoRoute(
      path: AppRoutes.addExpense,
      parentNavigatorKey: _rootNavigatorKey,
      // Presented like an iOS modal: slides up from the bottom.
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        child: const AddExpenseScreen(),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          ),
          child: child,
        ),
      ),
    ),
    for (final (path, screen) in [
      (AppRoutes.profileEdit, const EditProfileScreen()),
      (AppRoutes.profileCategories, const ManageCategoriesScreen()),
      (AppRoutes.profileSettings, const SettingsScreen()),
      (AppRoutes.profileSupport, const SupportScreen()),
      (AppRoutes.profilePrivacy, const PrivacyScreen()),
      (AppRoutes.profileAbout, const AboutScreen()),
    ])
      GoRoute(
        path: path,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => screen,
      ),
    GoRoute(
      path: '/profile/categories/:categoryId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ManageSubcategoriesScreen(
        categoryId: state.pathParameters['categoryId']!,
      ),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.statistics,
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const StatisticsScreen(),
        ),
        GoRoute(
          path: AppRoutes.history,
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
