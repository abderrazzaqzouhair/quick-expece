import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../router/app_routes.dart';

/// Wraps the bottom-nav tabs (Home / Statistics / History / Profile) inside
/// a `ShellRoute` so the nav bar persists across tab navigation. The center
/// "create" button isn't a tab — it pushes [AppRoutes.addExpense] full-screen
/// on the root navigator instead.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabRoutes = {
    AppNavTab.home: AppRoutes.home,
    AppNavTab.statistics: AppRoutes.statistics,
    AppNavTab.history: AppRoutes.history,
    AppNavTab.profile: AppRoutes.profile,
  };

  AppNavTab _tabForLocation(String location) {
    for (final entry in _tabRoutes.entries) {
      if (location.startsWith(entry.value)) return entry.key;
    }
    return AppNavTab.home;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentTab = _tabForLocation(location);

    return Scaffold(
      body: child,
      floatingActionButton: AppCreateFab(
        onPressed: () => context.push(AppRoutes.addExpense),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        elevation: 10,
        notchMargin: 6,
        height: 68,
        padding: EdgeInsets.zero,
        shape: const AppNotchedRectangle(cornerRadius: 28),
        child: AppBottomNavBar(
          currentTab: currentTab,
          onTabSelected: (tab) => context.go(_tabRoutes[tab]!),
        ),
      ),
    );
  }
}
