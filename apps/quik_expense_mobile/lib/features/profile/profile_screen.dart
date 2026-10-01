import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/app_info.dart';
import '../../config/router/app_routes.dart';
import '../../shared/formatters.dart';
import '../../shared/haptics.dart';
import '../../shared/widgets/confirm_sheet.dart';
import '../../shared/widgets/pressable.dart';
import 'data/profile_providers.dart';
import 'data/profile_store.dart';
import 'widgets/profile_avatar.dart';

/// Profile hub: top bar, colourful header, a white sheet with the centred avatar,
/// name and email, then glowing grouped rows — each opens its own screen
/// (edit profile, categories, settings, privacy, help, about) — and sign
/// out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _headerHeight = 150.0;
  static const _avatarSize = 96.0;

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await confirmDestructive(
      context,
      icon: Icons.logout_rounded,
      title: 'Sign out?',
      message:
          'Your expenses stay safely on this phone. You can sign back in '
          'any time.',
      confirmLabel: 'Sign Out',
    );
    if (!confirmed || !context.mounted) return;
    Haptics.medium();
    await TokenService.instance.clearSession();
    if (context.mounted) context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider).value;
    final shown = categories?.where((c) => c.isSelected).length;
    // The orange header runs up behind the top bar (extendBodyBehindAppBar)
    // so the bar's rounded bottom corners show against it, like on the
    // other tabs. Status bar + bar height:
    final appBar = AppTopBar(
      title: 'Profile',
      onProfileTap: () => context.push(AppRoutes.profileEdit),
    );
    final barArea =
        MediaQuery.paddingOf(context).top + appBar.preferredSize.height;
    final sheetTop = barArea + _headerHeight - 40;

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            SizedBox(
              height: barArea + _headerHeight,
              width: double.infinity,
              child: const _HeaderArt(),
            ),
            Container(
              margin: EdgeInsets.only(top: sheetTop),
              padding: const EdgeInsets.fromLTRB(
                20,
                _avatarSize / 2 + 14,
                20,
                120,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Identity(),
                  const SizedBox(height: 28),
                  _GlowGroup(
                    title: 'Account Settings',
                    children: [
                      _GlowTile(
                        icon: Icons.person_outline_rounded,
                        color: const Color(0xFF0D9488),
                        title: 'Edit Profile',
                        onTap: () => context.push(AppRoutes.profileEdit),
                      ),
                      _GlowTile(
                        icon: Icons.grid_view_outlined,
                        color: const Color(0xFF2563EB),
                        title: 'Categories',
                        value: categories == null
                            ? null
                            : '$shown of ${categories.length}',
                        onTap: () => context.push(AppRoutes.profileCategories),
                      ),
                      _GlowTile(
                        icon: Icons.tune_rounded,
                        color: const Color(0xFF7C3AED),
                        title: 'Settings',
                        onTap: () => context.push(AppRoutes.profileSettings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _GlowGroup(
                    title: 'Support & About',
                    children: [
                      _GlowTile(
                        icon: Icons.shield_outlined,
                        color: const Color(0xFFF59E0B),
                        title: 'Privacy & Security',
                        onTap: () => context.push(AppRoutes.profilePrivacy),
                      ),
                      _GlowTile(
                        icon: Icons.help_outline_rounded,
                        color: const Color(0xFF16A34A),
                        title: 'Help & Contact',
                        onTap: () => context.push(AppRoutes.profileSupport),
                      ),
                      _GlowTile(
                        icon: Icons.info_outline_rounded,
                        color: const Color(0xFF0EA5E9),
                        title: 'About ${AppInfo.name}',
                        value: AppInfo.version,
                        onTap: () => context.push(AppRoutes.profileAbout),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _GlowGroup(
                    glow: const Color(0xFFFF3B30),
                    children: [
                      _GlowTile(
                        icon: Icons.logout_rounded,
                        color: const Color(0xFFFF3B30),
                        title: 'Sign Out',
                        destructive: true,
                        onTap: () => _signOut(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Avatar straddles the sheet's top edge.
            Positioned(
              top: sheetTop - _avatarSize / 2,
              left: 0,
              right: 0,
              child: const Center(child: _RingedAvatar(size: _avatarSize)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand-orange gradient (same as Home's "Today" card and the Save
/// button) with a few faint white rings for depth.
class _HeaderArt extends StatelessWidget {
  const _HeaderArt();

  @override
  Widget build(BuildContext context) {
    Widget ring(double size, double alpha, {double stroke = 0}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: stroke == 0 ? Colors.white.withValues(alpha: alpha) : null,
        border: stroke == 0
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: alpha),
                width: stroke,
              ),
      ),
    );

    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -50, top: -60, child: ring(180, 0.10)),
            Positioned(right: 40, top: -20, child: ring(120, 0.14, stroke: 2)),
            Positioned(left: -40, bottom: -70, child: ring(160, 0.08)),
            Positioned(left: 60, top: 18, child: ring(14, 0.25)),
          ],
        ),
      ),
    );
  }
}

/// Avatar with a white ring and a thin coloured outer ring; tap to edit.
class _RingedAvatar extends ConsumerWidget {
  const _RingedAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Pressable(
      onTap: () => context.push(AppRoutes.profileEdit),
      semanticLabel: 'Edit profile photo and colour',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: profile.color,
          boxShadow: [
            BoxShadow(
              color: profile.color.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ProfileAvatar(profile: profile, size: size - 12),
        ),
      ),
    );
  }
}

/// Centred name, email, member-since and three compact live stats.
class _Identity extends ConsumerWidget {
  const _Identity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final summary = ref.watch(expenseSummaryProvider).value;

    return Column(
      children: [
        Text(
          profile.hasName ? profile.name : 'Add your name',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: profile.hasName ? AppColors.textPrimary : AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email.isNotEmpty
              ? profile.email
              : 'Member since ${DateFormat.yMMM('en_US').format(profile.memberSince)}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatCard(
                icon: Icons.receipt_long_rounded,
                tint: const Color(0xFF3B82F6),
                value: summary == null ? '–' : '${summary.count}',
                label: summary?.count == 1 ? 'Expense' : 'Expenses',
                onTap: () => context.go(AppRoutes.history),
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                tint: AppColors.primary,
                value: summary == null ? '–' : formatAmount(summary.totalCents),
                label: 'MAD spent',
                onTap: () => context.go(AppRoutes.statistics),
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.local_fire_department_rounded,
                tint: const Color(0xFF16A34A),
                value: trackingDuration(
                  summary?.firstDate ?? profile.memberSince,
                ),
                label: 'Tracking',
                onTap: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One stat: white card with a tinted icon badge, bold value and label.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.96,
        semanticLabel: '$value $label',
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F3F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: tint),
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey section title + white card with a soft tinted glow border.
class _GlowGroup extends StatelessWidget {
  const _GlowGroup({
    this.title,
    required this.children,
    this.glow = const Color(0xFF60A5FA),
  });

  final String? title;
  final List<Widget> children;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glow.withValues(alpha: 0.18), width: 4),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.10),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF1F3F5),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Row: coloured outline icon, title, optional value, chevron.
class _GlowTile extends StatelessWidget {
  const _GlowTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.value,
    this.destructive = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  final String? value;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: destructive ? color : AppColors.textPrimary,
                  ),
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Text(
                    value!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (!destructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
