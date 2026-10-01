import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Loading placeholder for everything below Home's calendar: summary
/// cards, Top Categories, Analytics and Recent Expenses — same sizes and
/// radii as the real sections so nothing jumps when they fade in.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeleton(
          child: Row(
            children: [
              Expanded(child: SkeletonBox(height: 86, radius: 20)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 86, radius: 20)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Card(
          radius: 28,
          padding: 24,
          child: AppSkeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeaderSkeleton(width: 150),
                const SizedBox(height: 24),
                SizedBox(
                  height: 128,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      SkeletonBox(width: 176, height: 128, radius: 22),
                      SizedBox(width: 14),
                      SkeletonBox(width: 176, height: 128, radius: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _Card(
          child: AppSkeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSkeleton(width: 100),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _LegendSkeleton()),
                    SizedBox(width: 16),
                    SkeletonBox(height: 140, circle: true),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _Card(
          child: AppSkeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSkeleton(width: 160),
                SizedBox(height: 8),
                SkeletonListRow(avatarSize: 40, titleWidth: 110),
                SkeletonListRow(avatarSize: 40, titleWidth: 84),
                SkeletonListRow(avatarSize: 40, titleWidth: 124),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Analytics legend: four name + amount line pairs.
class _LegendSkeleton extends StatelessWidget {
  const _LegendSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final w in const [110.0, 80.0, 96.0, 70.0]) ...[
          SkeletonBox(width: w, height: 12, radius: 6),
          const SizedBox(height: 6),
          const SkeletonBox(width: 64, height: 10, radius: 5),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Section title + "See all" placeholder.
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SkeletonBox(width: width, height: 18, radius: 9),
        const Spacer(),
        const SkeletonBox(width: 56, height: 14, radius: 7),
      ],
    );
  }
}

/// Real white card (stays solid) around shimmering content.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.radius = 20, this.padding = 20});

  final Widget child;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
