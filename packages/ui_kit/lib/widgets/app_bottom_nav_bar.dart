import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_assets.dart';
import '../theme/app_colors.dart';

/// The four selectable destinations in [AppBottomNavBar].
enum AppNavTab {
  home(AppAssets.iconHome, 'Home'),
  statistics(AppAssets.iconStatistics, 'Statistics'),
  history(AppAssets.iconHistory, 'History'),
  profile(AppAssets.iconProfile, 'Profile');

  const AppNavTab(this._assetPath, this.label);

  final String _assetPath;
  final String label;
}

/// The 4-tab row for the bottom nav — meant to be the `child` of a
/// `BottomAppBar`, not used standalone. The middle gap is reserved space
/// for [AppCreateFab], which is docked separately via
/// `Scaffold.floatingActionButton` + `FloatingActionButtonLocation.centerDocked`
/// so the app bar can cut a real notch around it (see [AppCreateFab] doc).
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final AppNavTab currentTab;
  final ValueChanged<AppNavTab> onTabSelected;

  static const _leftTabs = [AppNavTab.home, AppNavTab.statistics];
  static const _rightTabs = [AppNavTab.history, AppNavTab.profile];

  // Matches AppCreateFab's default `size` — the gap under the notch needs
  // to be roughly as wide as the button it's making room for.
  static const _fabGap = 66.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in _leftTabs)
          Expanded(
            child: _TabButton(
              tab: tab,
              isActive: tab == currentTab,
              onTap: () => onTabSelected(tab),
            ),
          ),
        const SizedBox(width: _fabGap),
        for (final tab in _rightTabs)
          Expanded(
            child: _TabButton(
              tab: tab,
              isActive: tab == currentTab,
              onTap: () => onTabSelected(tab),
            ),
          ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  static const _animationDuration = Duration(milliseconds: 200);

  final AppNavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: isActive,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: _animationDuration,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SvgPicture.asset(
                tab._assetPath,
                width: 21,
                height: 21,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: _animationDuration,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rectangle with rounded top corners *and* a smooth circular notch.
///
/// Flutter's built-in `CircularNotchedRectangle` produces exactly the
/// smooth, bezier-blended "flows into the edge" notch curve this needs, but
/// only for a plain sharp-cornered rectangle. `AutomaticNotchedShape` (a
/// naive boolean subtraction of a circle from a rounded rect) was tried
/// first and produces a harsh, angular bite instead — not what's wanted.
/// This reuses `CircularNotchedRectangle`'s exact control-point math
/// (verbatim, from the Flutter SDK source) and only replaces its two sharp
/// top corners with rounded arcs.
class AppNotchedRectangle extends NotchedShape {
  const AppNotchedRectangle({this.cornerRadius = 28});

  final double cornerRadius;

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    final radius = Radius.circular(cornerRadius);
    final rrect = RRect.fromRectAndCorners(
      host,
      topLeft: radius,
      topRight: radius,
    );

    if (guest == null || !host.overlaps(guest)) {
      return Path()..addRRect(rrect);
    }

    // The guest's shape is a circle bounded by the guest rectangle, so its
    // radius is half the guest width. Same derivation as
    // `CircularNotchedRectangle` (see https://goo.gl/Ufzrqn).
    final double r = guest.width / 2.0;
    final Radius notchRadius = Radius.circular(r);

    const double s1 = 15.0;
    const double s2 = 1.0;

    final double a = -r - s2;
    final double b = host.top - guest.center.dy;

    final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final double p2yA = math.sqrt(r * r - p2xA * p2xA);
    final double p2yB = math.sqrt(r * r - p2xB * p2xB);

    final List<Offset> p = List<Offset>.filled(6, Offset.zero);
    p[0] = Offset(a - s1, b);
    p[1] = Offset(a, b);
    final double cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);
    p[3] = Offset(-1.0 * p[2].dx, p[2].dy);
    p[4] = Offset(-1.0 * p[1].dx, p[1].dy);
    p[5] = Offset(-1.0 * p[0].dx, p[0].dy);
    for (var i = 0; i < p.length; i += 1) {
      p[i] += guest.center;
    }

    return Path()
      ..moveTo(host.left, host.top + cornerRadius)
      ..arcToPoint(Offset(host.left + cornerRadius, host.top), radius: radius)
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(p[3], radius: notchRadius, clockwise: false)
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(host.right - cornerRadius, host.top)
      ..arcToPoint(Offset(host.right, host.top + cornerRadius), radius: radius)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}

/// The center "create" action — a gradient circle with a soft glow and a
/// white border, floating half above / half nested into the concave notch
/// cut by [AppNotchedRectangle]. Passed as `Scaffold.floatingActionButton`
/// with `floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked`
/// — Flutter reads this widget's rendered position via `Scaffold.geometryOf`
/// and feeds it to the notch shape automatically (see `MainShell`).
class AppCreateFab extends StatefulWidget {
  const AppCreateFab({super.key, required this.onPressed, this.size = 66});

  final VoidCallback onPressed;
  final double size;

  @override
  State<AppCreateFab> createState() => _AppCreateFabState();
}

class _AppCreateFabState extends State<AppCreateFab> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create',
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              // A soft, centered (no offset) glow in all directions, kept
              // diffused rather than dark/harsh — two layers, a tighter one
              // close to the edge and a larger, softer one for the bloom.
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.iconAdd,
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(
                  AppColors.onPrimary,
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
