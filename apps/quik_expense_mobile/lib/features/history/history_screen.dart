import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';

/// UI-only — wires to the `expenses` package's providers once implemented.
/// This is the past-expenses list (hence "History" in the bottom nav).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'History',
        onProfileTap: () => context.go(AppRoutes.profile),
      ),
      body: const Center(child: Text('Past expenses go here')),
    );
  }
}
