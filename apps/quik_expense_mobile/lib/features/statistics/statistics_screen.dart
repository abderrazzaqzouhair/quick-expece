import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';

enum _Period {
  week('Week'),
  month('Month'),
  sixMonths('6M'),
  year('Year');

  const _Period(this.label);
  final String label;
}

/// UI-only — every number below is mock data (no real analytics provider
/// wired yet). Reuses the same 4 mock categories/colors/icons as
/// `HomeScreen`/`CategoriesScreen` so the app-wide "top categories" story
/// stays consistent; only the per-period totals are invented here.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  _Period _period = _Period.month;

  @override
  Widget build(BuildContext context) {
    final data = _PeriodData.forPeriod(_period);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Statistics',
        onProfileTap: () => context.go(AppRoutes.profile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 20),
            _StatsSummaryRow(data: data),
            const SizedBox(height: 24),
            _SectionCard(child: _SpendingTrendSection(data: data)),
            const SizedBox(height: 24),
            _InsightsRow(data: data),
            const SizedBox(height: 24),
            _SectionCard(child: _CategoryBreakdownSection(data: data)),
          ],
        ),
      ),
    );
  }
}

class _BarPoint {
  const _BarPoint({required this.label, required this.value});
  final String label;
  final double value;
}

class _CategorySpend {
  const _CategorySpend({
    required this.name,
    required this.color,
    required this.iconAsset,
    required this.amount,
    required this.deltaPercent,
  });

  final String name;
  final Color color;
  final String iconAsset;
  final double amount;

  /// Change vs the previous period, as a signed percentage — same mock
  /// figures Home's category cards use, held constant across periods like
  /// the shares are.
  final int deltaPercent;
}

/// Everything one period's worth of charts/summary needs, derived from a
/// deterministically-seeded mock bar series so re-selecting the same period
/// always shows the same numbers instead of reshuffling on every rebuild.
class _PeriodData {
  const _PeriodData({
    required this.period,
    required this.bars,
    required this.total,
    required this.previousTotal,
    required this.categories,
  });

  final _Period period;
  final List<_BarPoint> bars;
  final double total;
  final double previousTotal;
  final List<_CategorySpend> categories;

  double get deltaPercent =>
      previousTotal == 0 ? 0 : (total - previousTotal) / previousTotal * 100;

  String get averageLabel {
    switch (period) {
      case _Period.week:
        return 'Daily Avg';
      case _Period.month:
        return 'Weekly Avg';
      case _Period.sixMonths:
      case _Period.year:
        return 'Monthly Avg';
    }
  }

  double get average => bars.isEmpty ? 0 : total / bars.length;

  _BarPoint get highestBar => bars.reduce((a, b) => b.value > a.value ? b : a);

  _BarPoint get lowestBar => bars.reduce((a, b) => b.value < a.value ? b : a);

  // The real category catalogue only ships icons for these 4 — same subset
  // `HomeScreen`/`CategoriesScreen` mock. Shares are held constant across
  // periods (only the total each period scales to differs), which is a
  // simplification but keeps every period's breakdown internally coherent.
  static const _shares = [
    (
      name: 'Food & Drinks',
      color: Color(0xFFF59E0B),
      iconAsset: AppAssets.iconCategoryFood,
      share: 0.43,
      delta: 12,
    ),
    (
      name: 'Transport',
      color: Color(0xFF3B82F6),
      iconAsset: AppAssets.iconCategoryTransport,
      share: 0.26,
      delta: -8,
    ),
    (
      name: 'Entertainment & Fun',
      color: Color(0xFF8B5CF6),
      iconAsset: AppAssets.iconCategoryEntertainment,
      share: 0.18,
      delta: 22,
    ),
    (
      name: 'Subscriptions & Digital',
      color: Color(0xFF6366F1),
      iconAsset: AppAssets.iconCategorySubscriptions,
      share: 0.13,
      delta: -5,
    ),
  ];

  static _PeriodData forPeriod(_Period period) {
    final bars = _mockBars(period);
    final total = bars.fold(0.0, (sum, b) => sum + b.value);
    // A flat 12% lower "previous period" — good enough to drive the trend
    // arrow on mock data without a second real series to compare against.
    final previousTotal = total / 1.12;
    final categories = [
      for (final s in _shares)
        _CategorySpend(
          name: s.name,
          color: s.color,
          iconAsset: s.iconAsset,
          amount: total * s.share,
          deltaPercent: s.delta,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return _PeriodData(
      period: period,
      bars: bars,
      total: total,
      previousTotal: previousTotal,
      categories: categories,
    );
  }

  static List<_BarPoint> _mockBars(_Period period) {
    final now = DateTime.now();
    switch (period) {
      case _Period.week:
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const values = [28.5, 15.75, 42.0, 60.25, 33.1, 98.4, 67.75];
        return [
          for (var i = 0; i < labels.length; i++)
            _BarPoint(label: labels[i], value: values[i]),
        ];
      case _Period.month:
        const labels = ['W1', 'W2', 'W3', 'W4'];
        const values = [210.0, 305.5, 180.75, 352.0];
        return [
          for (var i = 0; i < labels.length; i++)
            _BarPoint(label: labels[i], value: values[i]),
        ];
      case _Period.sixMonths:
        return _rollingMonths(now, 6);
      case _Period.year:
        return _rollingMonths(now, 12);
    }
  }

  /// [count] months ending at the current one, each labeled with its own
  /// short month name — deterministically seeded so the series is stable
  /// across rebuilds, with a mild upward drift toward the present so the
  /// chart reads as a trend rather than pure noise.
  static List<_BarPoint> _rollingMonths(DateTime now, int count) {
    final random = math.Random(count);
    return [
      for (var i = count - 1; i >= 0; i--)
        _BarPoint(
          label: DateFormat.MMM(
            'en_US',
          ).format(DateTime(now.year, now.month - i)),
          value: (650 + (count - i) * 18 + random.nextDouble() * 260 - 60)
              .clamp(300, 1400)
              .toDouble(),
        ),
    ];
  }
}

String _formatMad(double amount) =>
    '${NumberFormat('#,##0.00', 'en_US').format(amount)} MAD';

/// iOS-style segmented control: a light track with a white sliding pill
/// behind whichever period is selected — same rounded, shadow-soft language
/// as the rest of the app rather than Flutter's default `SegmentedButton`.
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final _Period selected;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final period in _Period.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: period == selected
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: period == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    period.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: period == selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Total spent + period average, in the same two-gradient-tile language as
/// Home's day/month summary cards.
class _StatsSummaryRow extends StatelessWidget {
  const _StatsSummaryRow({required this.data});

  final _PeriodData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientStatCard(
            label: 'Total Spent',
            amount: data.total,
            gradientColors: [
              Color.lerp(AppColors.textPrimary, Colors.white, 0.18)!,
              AppColors.textPrimary,
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientStatCard(
            label: data.averageLabel,
            amount: data.average,
            gradientColors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
      ],
    );
  }
}

class _GradientStatCard extends StatelessWidget {
  const _GradientStatCard({
    required this.label,
    required this.amount,
    required this.gradientColors,
  });

  final String label;
  final double amount;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatMad(amount),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three compact "highlight" tiles — highest bucket, lowest bucket, and the
/// period's leading category — the "add one subtle element" insight row a
/// pure chart-and-legend screen was missing.
class _InsightsRow extends StatelessWidget {
  const _InsightsRow({required this.data});

  final _PeriodData data;

  @override
  Widget build(BuildContext context) {
    final topCategory = data.categories.first;
    return Row(
      children: [
        Expanded(
          child: _InsightTile(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFFE5484D),
            label: 'Highest',
            value: data.highestBar.label,
            amount: data.highestBar.value,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightTile(
            icon: Icons.trending_down_rounded,
            iconColor: const Color(0xFF2FB457),
            label: 'Lowest',
            value: data.lowestBar.label,
            amount: data.lowestBar.value,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightTile(
            icon: Icons.emoji_events_rounded,
            iconColor: topCategory.color,
            label: 'Top Category',
            value: topCategory.name,
            amount: topCategory.amount,
          ),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _formatMad(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart of the period's buckets (days/weeks/months): the current bucket
/// picked out in the full brand color (the rest a soft tint) so the eye
/// lands on "where am I now" rather than an arbitrary peak, a dashed line
/// marks the period average, and tapping a bar shows its exact amount.
class _SpendingTrendSection extends StatelessWidget {
  const _SpendingTrendSection({required this.data});

  final _PeriodData data;

  @override
  Widget build(BuildContext context) {
    final isUp = data.deltaPercent >= 0;
    // Spending more than the previous period is the "watch out" direction —
    // same red-up/green-down convention as the category trend pills
    // elsewhere in the app.
    final deltaColor = isUp ? const Color(0xFFE5484D) : const Color(0xFF2FB457);
    final maxValue = data.bars.fold(0.0, (m, b) => math.max(m, b.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Trend',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Icon(
                  isUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: deltaColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '${data.deltaPercent.abs().round()}% vs last period',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: deltaColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              maxY: maxValue * 1.25,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: data.average,
                    color: AppColors.textSecondary.withValues(alpha: 0.35),
                    strokeWidth: 1,
                    dashArray: const [5, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(bottom: 4),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      labelResolver: (_) => 'Avg',
                    ),
                  ),
                ],
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        _formatMad(rod.toY),
                        const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.bars.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          data.bars[i].label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < data.bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data.bars[i].value,
                        width: data.period == _Period.week ? 18 : 14,
                        borderRadius: BorderRadius.circular(6),
                        color: i == data.bars.length - 1
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.16),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Donut chart + ranked legend rows — a different chart shape than Home's
/// exploded pie so the two screens don't feel like copies of each other,
/// while keeping the same colors/fonts.
class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({required this.data});

  final _PeriodData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'By Category',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 46,
                  sectionsSpace: 3,
                  startDegreeOffset: -90,
                  sections: [
                    for (final c in data.categories)
                      PieChartSectionData(
                        value: c.amount,
                        color: c.color,
                        radius: 28,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    NumberFormat('#,##0', 'en_US').format(data.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'MAD total',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < data.categories.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == data.categories.length - 1 ? 0 : 14,
            ),
            child: _CategoryLegendRow(
              category: data.categories[i],
              shareOfTotal: data.total == 0
                  ? 0
                  : data.categories[i].amount / data.total,
            ),
          ),
      ],
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.category,
    required this.shareOfTotal,
  });

  final _CategorySpend category;
  final double shareOfTotal;

  @override
  Widget build(BuildContext context) {
    final isUp = category.deltaPercent >= 0;
    final deltaColor = isUp ? const Color(0xFFE5484D) : const Color(0xFF2FB457);

    return Row(
      children: [
        AppIconBadge(
          assetPath: category.iconAsset,
          color: category.color,
          backgroundAlpha: 0.12,
          size: 32,
          iconSize: 17,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 10,
                    color: deltaColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${category.deltaPercent.abs()}% vs last period',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: deltaColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(shareOfTotal * 100).round()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: category.color,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            _formatMad(category.amount),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable white "card" wrapper — flat white background + soft shadow,
/// matching Home's section cards.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
