import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';
import '../../shared/category_visuals.dart';
import '../../shared/formatters.dart';
import '../../shared/spending.dart';
import '../../shared/widgets/period_selector.dart';
import '../expense_list/expense_list_controller.dart';
import 'logic/period_stats.dart';
import 'widgets/statistics_skeleton.dart';
import '../../shared/haptics.dart';

/// Spending analytics for a period (this week / this month / last 6 months
/// / last 12 months / all time), live from the local database, each
/// compared with the period just before it (all time has nothing to
/// compare against).
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatsPeriod _period = StatsPeriod.month;

  /// Last computed stats — kept while another period loads so switching
  /// doesn't flash back to the skeleton.
  PeriodStats? _lastStats;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final window = windowFor(_period, now);
    final data = ref.watch(expensesInRangeProvider(window.loadRange));
    if (data.hasValue) {
      _lastStats = buildPeriodStats(_period, window, data.value!, now);
    }
    final stats = _lastStats;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Statistics',
        onProfileTap: () => context.go(AppRoutes.profile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PeriodSelector(
              selected: _period,
              onChanged: (p) {
                Haptics.selection();
                setState(() => _period = p);
              },
            ),
            const SizedBox(height: 20),
            SkeletonSwitcher(
              isLoading: stats == null,
              skeleton: const StatisticsSkeleton(),
              child: stats == null
                  ? const SizedBox.shrink()
                  : AnimatedOpacity(
                      opacity: data.isLoading ? 0.6 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: _StatsBody(
                        stats: stats,
                        onViewAll: () {
                          Haptics.selection();
                          ref
                              .read(expenseListControllerProvider.notifier)
                              .openFor(stats.period);
                          context.push(AppRoutes.expenses);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats, required this.onViewAll});

  final PeriodStats stats;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsSummaryRow(stats: stats),
        const SizedBox(height: 24),
        if (stats.isEmpty)
          _SectionCard(
            child: _EmptyPeriod(
              period: stats.period,
              onAdd: () => context.push(AppRoutes.addExpense),
            ),
          )
        else ...[
          _SectionCard(child: _SpendingTrendSection(stats: stats)),
          const SizedBox(height: 24),
          _InsightsRow(stats: stats),
          const SizedBox(height: 24),
          _SectionCard(child: _CategoryBreakdownSection(stats: stats)),
          const SizedBox(height: 20),
          _ViewAllExpensesButton(onTap: onViewAll),
        ],
      ],
    );
  }
}

/// Full-width CTA to the expense list screen, scoped to the active period.
class _ViewAllExpensesButton extends StatelessWidget {
  const _ViewAllExpensesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'View All Expenses',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _colorOf(CategorySpend spend) =>
    CategoryVisuals.colorFor(spend.category.color);

String _periodPhrase(StatsPeriod period) => switch (period) {
  StatsPeriod.week => 'this week',
  StatsPeriod.month => 'this month',
  StatsPeriod.sixMonths => 'in the last 6 months',
  StatsPeriod.year => 'in the last 12 months',
  StatsPeriod.all => 'yet',
};

/// Full name of a bucket for the insight tiles: "Wednesday", "Week 2",
/// "Sep 2026".
String _bucketName(StatsPeriod period, StatsBucket bucket) => switch (period) {
  StatsPeriod.week => DateFormat.EEEE('en_US').format(bucket.range.from),
  StatsPeriod.month => 'Week ${bucket.label.substring(1)}',
  StatsPeriod.sixMonths ||
  StatsPeriod.year => DateFormat.yMMM('en_US').format(bucket.range.from),
  StatsPeriod.all => bucket.label,
};

/// Total spent + period average, in the same two-gradient-tile language as
/// Home's day/month summary cards.
class _StatsSummaryRow extends StatelessWidget {
  const _StatsSummaryRow({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientStatCard(
            label: 'Total Spent',
            amountCents: stats.totalCents,
            gradientColors: [
              Color.lerp(AppColors.textPrimary, Colors.white, 0.18)!,
              AppColors.textPrimary,
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientStatCard(
            label: stats.period.averageLabel,
            amountCents: stats.averageCents,
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
    required this.amountCents,
    required this.gradientColors,
  });

  final String label;
  final int amountCents;
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                formatMad(amountCents),
                key: ValueKey(amountCents),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nothing recorded in the period — explain and offer the next action.
class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod({required this.period, required this.onAdd});

  final StatsPeriod period;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No expenses ${_periodPhrase(period)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your trends, highlights and category breakdown will appear '
            'here once you add expenses.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, 44),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Add expense',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Highest bucket, lowest bucket (both among buckets that have started) and
/// the period's leading category.
class _InsightsRow extends StatelessWidget {
  const _InsightsRow({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final highest = stats.highest!;
    final lowest = stats.lowest!;
    final top = stats.categories.first;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InsightTile(
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFFE5484D),
              label: 'Highest',
              value: _bucketName(stats.period, highest),
              amountCents: highest.totalCents,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InsightTile(
              icon: Icons.trending_down_rounded,
              iconColor: const Color(0xFF2FB457),
              label: 'Lowest',
              value: _bucketName(stats.period, lowest),
              amountCents: lowest.totalCents,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InsightTile(
              icon: Icons.emoji_events_rounded,
              iconColor: _colorOf(top),
              label: 'Top Category',
              value: top.category.name,
              amountCents: top.totalCents,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.amountCents,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final int amountCents;

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
            formatMad(amountCents),
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

/// Bar chart of the period's buckets: the current bucket in full brand
/// color, past ones a soft tint, future ones barely there; a dashed line
/// marks the average; tapping a bar shows its exact amount.
class _SpendingTrendSection extends StatelessWidget {
  const _SpendingTrendSection({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final delta = stats.deltaPercent;
    final buckets = stats.buckets;
    final maxCents = buckets.fold(0, (m, b) => math.max(m, b.totalCents));
    // Spending more than last period is the "watch out" direction.
    final deltaColor = delta == null
        ? AppColors.textSecondary
        : delta >= 0
        ? const Color(0xFFE5484D)
        : const Color(0xFF2FB457);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Spending Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (delta != null)
              Icon(
                delta >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: deltaColor,
              ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                delta == null
                    ? 'Nothing last period'
                    : '${delta.abs()}% vs last period',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              maxY: math.max(maxCents, 1) / 100 * 1.25,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (stats.averageCents > 0)
                    HorizontalLine(
                      y: stats.averageCents / 100,
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
                        formatMad(buckets[group.x].totalCents),
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
                      if (i < 0 || i >= buckets.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          // 12 month labels are too tight — first letter.
                          stats.period == StatsPeriod.year
                              ? buckets[i].label.substring(0, 1)
                              : buckets[i].label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: buckets[i].isCurrent(stats.now)
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: buckets[i].isCurrent(stats.now)
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < buckets.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: buckets[i].totalCents / 100,
                        width: switch (stats.period) {
                          StatsPeriod.week => 18,
                          StatsPeriod.year => 12,
                          _ => 14,
                        },
                        borderRadius: BorderRadius.circular(6),
                        color: buckets[i].isCurrent(stats.now)
                            ? AppColors.primary
                            : buckets[i].isFuture(stats.now)
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : AppColors.primary.withValues(alpha: 0.22),
                        // Soft full-height track behind every bar, so empty
                        // buckets still read as part of the axis.
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: math.max(maxCents, 1) / 100 * 1.25,
                          color: AppColors.background,
                        ),
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

/// Donut chart + ranked legend rows.
class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final categories = stats.categories;
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
                  sectionsSpace: categories.length > 1 ? 3 : 0,
                  startDegreeOffset: -90,
                  sections: [
                    for (final c in categories)
                      PieChartSectionData(
                        value: c.totalCents.toDouble(),
                        color: _colorOf(c),
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
                    NumberFormat(
                      '#,##0',
                      'en_US',
                    ).format(stats.totalCents / 100),
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
        for (var i = 0; i < categories.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == categories.length - 1 ? 0 : 14,
            ),
            child: _CategoryLegendRow(
              spend: categories[i],
              shareOfTotal: categories[i].totalCents / stats.totalCents,
            ),
          ),
      ],
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({required this.spend, required this.shareOfTotal});

  final CategorySpend spend;
  final double shareOfTotal;

  @override
  Widget build(BuildContext context) {
    final delta = spend.deltaPercent;
    final color = _colorOf(spend);
    final deltaColor = delta == null
        ? color
        : delta >= 0
        ? const Color(0xFFE5484D)
        : const Color(0xFF2FB457);

    return Row(
      children: [
        CategoryAvatar(
          name: spend.category.name,
          colorHex: spend.category.color,
          size: 32,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spend.category.name,
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
                    delta == null
                        ? Icons.auto_awesome_rounded
                        : delta >= 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 10,
                    color: deltaColor,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      delta == null ? 'New' : '${delta.abs()}% vs last period',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: deltaColor,
                      ),
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
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        // Shrinks (rather than overflows) for huge amounts / large text.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatMad(spend.totalCents),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
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
