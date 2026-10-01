import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// UI-only — wires to the `profile` package's providers once implemented.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Profile'),
      body: const Center(child: Text('Profile details go here')),
    );
  }
}
