import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Loading placeholder for everything below the period selector: summary
/// tiles, trend chart, insight tiles and the category breakdown.
class StatisticsSkeleton extends StatelessWidget {
  const StatisticsSkeleton({super.key});

  static const _bars = [0.45, 0.7, 0.35, 0.9, 0.55, 0.8, 0.3];

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
        const SizedBox(height: 24),
        _Card(
          child: AppSkeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SkeletonBox(width: 120, height: 14, radius: 7),
                    Spacer(),
                    SkeletonBox(width: 96, height: 11, radius: 6),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final f in _bars)
                        SkeletonBox(width: 18, height: 120 * f, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const AppSkeleton(
          child: Row(
            children: [
              Expanded(child: SkeletonBox(height: 92, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 92, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 92, radius: 16)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _Card(
          child: AppSkeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 14, radius: 7),
                SizedBox(height: 20),
                Center(child: SkeletonBox(height: 150, circle: true)),
                SizedBox(height: 12),
                SkeletonListRow(avatarSize: 32, titleWidth: 120),
                SkeletonListRow(avatarSize: 32, titleWidth: 90),
                SkeletonListRow(avatarSize: 32, titleWidth: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Real white card (stays solid) around shimmering content.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
