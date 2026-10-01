import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_assets.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

/// The app's top-level tab bar — logo at the start, the current tab's name
/// centered, a profile avatar at the end. This is for the 4 bottom-nav tab
/// screens specifically; a pushed screen (e.g. add-expense) should use a
/// plain `AppBar` with its automatic back button instead — putting the logo
/// in `leading` here would replace that back arrow.
///
/// White surface + rounded bottom corners + soft shadow — the same
/// "floating card" treatment as [AppBottomNavBar], so the tab content sits
/// bookended between two matching bars instead of the top bar just
/// blending flat into the page background.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.onProfileTap});

  final String title;
  final VoidCallback? onProfileTap;

  static const _radius = 24.0;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_radius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_radius),
        ),
        child: AppBar(
          leadingWidth: 64,
          leading: const Padding(
            padding: EdgeInsets.only(left: 20),
            child: AppLogo(size: 32),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: _ProfileAvatar(onTap: onProfileTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Profile',
        child: Material(
          shape: const CircleBorder(),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: SvgPicture.asset(
                AppAssets.iconProfile,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
