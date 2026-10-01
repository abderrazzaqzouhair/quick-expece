import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A tinted circular badge around a bundled SVG icon — the "colored circle +
/// icon" pattern repeated across quick actions, transaction rows, and
/// insight cards. Centralized here so the app doesn't need its own
/// `flutter_svg` dependency just to render `ui_kit`'s bundled icons.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.assetPath,
    required this.color,
    this.size = 40,
    this.iconSize = 19,
    this.backgroundAlpha = 0.1,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.border,
  });

  final String assetPath;
  final Color color;
  final double size;
  final double iconSize;
  final double backgroundAlpha;

  // All optional: unset renders the default flat tinted circle. Set them to
  // get a rounded-square badge with its own background (e.g. a white square
  // on a colored card) and its own elevation instead of the flat circle
  // tinted by [color]. [gradient] takes precedence over the solid fill —
  // use it for a vivid iOS "app icon" squircle.
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient != null
            ? null
            : (backgroundColor ?? color.withValues(alpha: backgroundAlpha)),
        gradient: gradient,
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        border: border,
      ),
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
