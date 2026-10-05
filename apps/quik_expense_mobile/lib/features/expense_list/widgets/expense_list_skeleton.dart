import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Loading placeholder mirroring the expense list layout — period
/// selector, summary row, search field, category chips, and a couple of
/// rows — so nothing jumps when the real content fades in.
class ExpenseListSkeleton extends StatelessWidget {
  const ExpenseListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        AppSkeleton(child: SkeletonBox(height: 48, radius: 14)),
        const SizedBox(height: 20),
        AppSkeleton(child: SkeletonBox(width: 160, height: 14, radius: 7)),
        const SizedBox(height: 16),
        const AppSkeleton(child: SkeletonBox(height: 44, radius: 14)),
        const SizedBox(height: 12),
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
        const _RowsSkeleton(rows: 4),
      ],
    );
  }
}

class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppSkeleton(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++)
              SkeletonListRow(
                titleWidth: const [110.0, 84.0, 128.0, 96.0][i % 4],
                subtitleWidth: const [150.0, 120.0, 170.0, 140.0][i % 4],
              ),
          ],
        ),
      ),
    );
  }
}
