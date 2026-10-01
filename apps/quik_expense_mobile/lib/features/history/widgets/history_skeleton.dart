import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Loading placeholder that mirrors the History layout — month card, search
/// field, category chips and two day sections — so nothing jumps when the
/// real content fades in.
class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        const _MonthCardSkeleton(),
        const SizedBox(height: 16),
        const AppSkeleton(child: SkeletonBox(height: 44, radius: 14)),
        const SizedBox(height: 12),
        // Chips scroll sideways in the real UI, so clip at the edge too.
        SizedBox(
          height: 44,
          child: AppSkeleton(
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final width in [132.0, 116.0, 96.0, 110.0]) ...[
                  SkeletonBox(width: width, height: 44, radius: 22),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        const _DaySectionSkeleton(rows: 3),
        const _DaySectionSkeleton(rows: 2),
      ],
    );
  }
}

/// Dark card with light shimmer bars, matching `MonthSummaryCard`.
class _MonthCardSkeleton extends StatelessWidget {
  const _MonthCardSkeleton();

  static const _bars = [
    10.0, 24.0, 6.0, 38.0, 18.0, 3.0, 30.0, 12.0, 44.0, 8.0, 22.0, 3.0, //
    16.0, 34.0, 20.0, 5.0, 28.0, 14.0, 40.0, 9.0, 3.0, 26.0, 18.0, 32.0, //
    11.0, 3.0, 24.0, 15.0, 36.0, 7.0,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 236,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2B2E), Color(0xFF151517)],
        ),
      ),
      child: AppSkeleton.onDark(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SkeletonBox(width: 120, height: 14, radius: 7)),
            const SizedBox(height: 22),
            const SkeletonBox(width: 48, height: 11, radius: 6),
            const SizedBox(height: 10),
            const SkeletonBox(width: 190, height: 32, radius: 10),
            const SizedBox(height: 10),
            const SkeletonBox(width: 150, height: 11, radius: 6),
            const Spacer(),
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final h in _bars)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: SkeletonBox(height: h, radius: 3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySectionSkeleton extends StatelessWidget {
  const _DaySectionSkeleton({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 22, 4, 10),
          child: AppSkeleton(
            child: Row(
              children: [
                SkeletonBox(width: 72, height: 14, radius: 7),
                Spacer(),
                SkeletonBox(width: 64, height: 12, radius: 6),
              ],
            ),
          ),
        ),
        // The white card stays real; only its contents shimmer.
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AppSkeleton(
            child: Column(
              children: [
                for (var i = 0; i < rows; i++)
                  SkeletonListRow(
                    titleWidth: const [110.0, 84.0, 128.0][i % 3],
                    subtitleWidth: const [150.0, 120.0, 170.0][i % 3],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
