import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmering placeholder wrapper — everything painted inside [child] is
/// replaced by the moving grey gradient, so build the placeholder shapes
/// from [SkeletonBox]es and keep real surfaces (white cards) *outside* it.
///
/// The shimmer stops (static grey) when the OS asks for reduced motion.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, required this.child})
    : baseColor = const Color(0xFFE6E8EB),
      highlightColor = const Color(0xFFF6F7F9);

  /// For placeholders on a dark surface (e.g. the month summary card).
  const AppSkeleton.onDark({super.key, required this.child})
    : baseColor = const Color(0x1AFFFFFF),
      highlightColor = const Color(0x38FFFFFF);

  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1400),
        enabled: !MediaQuery.disableAnimationsOf(context),
        child: child,
      ),
    );
  }
}

/// A placeholder shape inside [AppSkeleton]: rounded rectangle, or a circle
/// when [circle] is set. Width defaults to filling the available space.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        // Any opaque colour — the shimmer gradient repaints it.
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A placeholder list row: rounded-square avatar, two text lines, trailing
/// value — the shape of most rows in the app.
class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({
    super.key,
    this.avatarSize = 42,
    this.titleWidth = 120,
    this.subtitleWidth = 180,
    this.trailingWidth = 56,
  });

  final double avatarSize;
  final double titleWidth;
  final double? subtitleWidth;
  final double? trailingWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SkeletonBox(
            width: avatarSize,
            height: avatarSize,
            radius: avatarSize * 0.3,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: titleWidth, height: 14, radius: 7),
                if (subtitleWidth != null) ...[
                  const SizedBox(height: 8),
                  SkeletonBox(width: subtitleWidth, height: 11, radius: 6),
                ],
              ],
            ),
          ),
          if (trailingWidth != null) ...[
            const SizedBox(width: 12),
            SkeletonBox(width: trailingWidth, height: 14, radius: 7),
          ],
        ],
      ),
    );
  }
}

/// Cross-fades from a skeleton to the real content when [isLoading] flips,
/// so fast loads don't "pop" and slow ones feel continuous.
class SkeletonSwitcher extends StatelessWidget {
  const SkeletonSwitcher({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
  });

  final bool isLoading;
  final Widget skeleton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(
        key: ValueKey(isLoading),
        child: isLoading ? skeleton : child,
      ),
    );
  }
}
