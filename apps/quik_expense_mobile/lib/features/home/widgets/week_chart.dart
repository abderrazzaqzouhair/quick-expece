import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/formatters.dart';

/// The selected day's week as 7 bars (Mon–Sun): week total and daily
/// average on top; the selected day in brand orange with its amount; past
/// days tinted, future days faint. Tapping a bar selects that day.
class WeekChart extends StatelessWidget {
  const WeekChart({
    super.key,
    required this.days,
    required this.totals,
    required this.selectedDay,
    required this.onDayTap,
  });

  /// 7 consecutive days, Monday first.
  final List<DateTime> days;

  /// Cents per day, same order as [days].
  final List<int> totals;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDayTap;

  /// Bars + labels; the bars take whatever the labels leave.
  static const _chartHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final weekTotal = totals.fold(0, (a, b) => a + b);
    final elapsed = days.where((d) => !d.isAfter(today)).length;
    final average = elapsed == 0 ? 0 : weekTotal ~/ elapsed;
    final maxTotal = totals.fold(0, math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMad(weekTotal),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'avg ${formatAmount(average)} / day',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: _chartHeight * MediaQuery.textScalerOf(context).scale(1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _DayBar(
                    day: days[i],
                    cents: totals[i],
                    fraction: maxTotal == 0 ? 0 : totals[i] / maxTotal,
                    isSelected: days[i] == selectedDay,
                    isToday: days[i] == today,
                    isFuture: days[i].isAfter(today),
                    onTap: () => onDayTap(days[i]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.cents,
    required this.fraction,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime day;
  final int cents;
  final double fraction;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSpend = cents > 0;
    final Color barColor;
    if (isSelected) {
      barColor = AppColors.primary;
    } else if (isFuture) {
      barColor = AppColors.primary.withValues(alpha: 0.06);
    } else {
      barColor = AppColors.primary.withValues(alpha: hasSpend ? 0.22 : 0.10);
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${DateFormat.EEEE('en_US').format(day)}: '
          '${hasSpend ? formatMad(cents) : 'nothing spent'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            // Amount above the selected bar only — keeps the chart calm.
            AnimatedOpacity(
              opacity: isSelected && hasSpend ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatAmount(cents),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: hasSpend
                        ? math.max(8.0, fraction * constraints.maxHeight)
                        : 6.0,
                    width: 26,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat.E('en_US').format(day).substring(0, 1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : isFuture
                    ? AppColors.textSecondary.withValues(alpha: 0.6)
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
