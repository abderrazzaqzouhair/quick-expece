import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

/// UI-only — the "See all" destination from Home's Top Categories section.
/// Mirrors the same mock category data (name/color/icon/amount) as
/// `HomeScreen` so the two screens read as one consistent demo instead of
/// unrelated numbers; wires to the real `categories` package's providers
/// once they exist.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _categories = [
    _CategorySpend(
      name: 'Food & Drinks',
      color: Color(0xFFF59E0B),
      iconAsset: AppAssets.iconCategoryFood,
      amount: 450.00,
      monthlyDeltaPercent: 12,
    ),
    _CategorySpend(
      name: 'Transport',
      color: Color(0xFF3B82F6),
      iconAsset: AppAssets.iconCategoryTransport,
      amount: 275.50,
      monthlyDeltaPercent: -8,
    ),
    _CategorySpend(
      name: 'Entertainment & Fun',
      color: Color(0xFF8B5CF6),
      iconAsset: AppAssets.iconCategoryEntertainment,
      amount: 190.00,
      monthlyDeltaPercent: 22,
    ),
    _CategorySpend(
      name: 'Subscriptions & Digital',
      color: Color(0xFF6366F1),
      iconAsset: AppAssets.iconCategorySubscriptions,
      amount: 132.75,
      monthlyDeltaPercent: -5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ranked = [..._categories]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = ranked.fold(0.0, (sum, c) => sum + c.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _TotalSpendCard(total: total),
          const SizedBox(height: 24),
          for (final category in ranked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryListTile(
                category: category,
                shareOfTotal: total == 0 ? 0 : category.amount / total,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySpend {
  const _CategorySpend({
    required this.name,
    required this.color,
    required this.iconAsset,
    required this.amount,
    required this.monthlyDeltaPercent,
  });

  final String name;
  final Color color;
  final String iconAsset;
  final double amount;
  final int monthlyDeltaPercent;
}

String _formatMad(double amount) =>
    '${NumberFormat('#,##0.00', 'en_US').format(amount)} MAD';

/// This month's total across every category — the dark gradient tile from
/// Home's "This Month" summary card, so the two screens share one visual
/// language for "the big number".
class _TotalSpendCard extends StatelessWidget {
  const _TotalSpendCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.textPrimary, Colors.white, 0.18)!,
            AppColors.textPrimary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spent This Month',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatMad(total),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row per category: icon + name + trend on top, amount on the right,
/// and a share-of-total progress bar underneath — the "subtle element that
/// makes the card feel alive" a plain list row is missing.
class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({required this.category, required this.shareOfTotal});

  final _CategorySpend category;
  final double shareOfTotal;

  static const _trendDown = Color(0xFF2FB457);
  static const _trendUp = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final delta = category.monthlyDeltaPercent;
    final isUp = delta >= 0;
    final trendIcon = isUp
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final trendColor = isUp ? _trendUp : _trendDown;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppIconBadge(
                assetPath: category.iconAsset,
                color: category.color,
                backgroundAlpha: 0.12,
                size: 40,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(trendIcon, size: 12, color: trendColor),
                        const SizedBox(width: 3),
                        Text(
                          '${delta.abs()}% vs last mo.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatMad(category.amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: shareOfTotal.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(category.color),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(shareOfTotal * 100).round()}% of spend',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
