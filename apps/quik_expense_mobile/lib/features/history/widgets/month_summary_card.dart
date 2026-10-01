import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/haptics.dart';

/// Dark hero card: month switcher, month total, and one bar per day.
/// Tapping a bar filters the list to that day (tap again to clear).
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    super.key,
    required this.month,
    required this.totalCents,
    required this.count,
    required this.dailyTotals,
    required this.selectedDay,
    required this.canGoForward,
    required this.onShiftMonth,
    required this.onDayTap,
  });

  final DateTime month;
  final int totalCents;
  final int count;
  final List<int> dailyTotals;
  final DateTime? selectedDay;
  final bool canGoForward;
  final ValueChanged<int> onShiftMonth;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final elapsedDays = isCurrentMonth ? now.day : dailyTotals.length;
    final avgCents = elapsedDays == 0 ? 0 : totalCents ~/ elapsedDays;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2B2E), Color(0xFF151517)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ArrowButton(
                icon: Icons.chevron_left_rounded,
                label: 'Previous month',
                onTap: () => onShiftMonth(-1),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    DateFormat('MMMM yyyy').format(month),
                    key: ValueKey(month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              _ArrowButton(
                icon: Icons.chevron_right_rounded,
                label: 'Next month',
                onTap: canGoForward ? () => onShiftMonth(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spent',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: formatAmount(totalCents)),
                        TextSpan(
                          text: '  MAD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count ${count == 1 ? 'expense' : 'expenses'}'
                  '  ·  ${formatAmount(avgCents)} / day',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 18),
                _DailyBars(
                  month: month,
                  totals: dailyTotals,
                  selectedDay: selectedDay,
                  onTap: onDayTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              Haptics.selection();
              onTap!();
            },
      semanticLabel: label,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 26,
          color: Colors.white.withValues(alpha: onTap == null ? 0.2 : 0.85),
        ),
      ),
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({
    required this.month,
    required this.totals,
    required this.selectedDay,
    required this.onTap,
  });

  final DateTime month;
  final List<int> totals;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onTap;

  static const _maxBarHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final maxTotal = totals.fold(0, math.max);

    return Column(
      children: [
        SizedBox(
          height: _maxBarHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < totals.length; i++)
                Expanded(
                  child: _Bar(
                    day: DateTime(month.year, month.month, i + 1),
                    cents: totals[i],
                    fraction: maxTotal == 0 ? 0 : totals[i] / maxTotal,
                    today: today,
                    selectedDay: selectedDay,
                    onTap: onTap,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < totals.length; i++)
              Expanded(
                child: Text(
                  // Weekly ticks keep the axis readable.
                  i % 7 == 0 ? '${i + 1}' : '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.cents,
    required this.fraction,
    required this.today,
    required this.selectedDay,
    required this.onTap,
  });

  final DateTime day;
  final int cents;
  final double fraction;
  final DateTime today;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final isFuture = day.isAfter(today);
    final isToday = day == today;
    final isSelected = day == selectedDay;
    final hasSpend = cents > 0;

    final Color color;
    if (isSelected) {
      color = Colors.white;
    } else if (isToday) {
      color = AppColors.primary;
    } else if (selectedDay != null) {
      color = Colors.white.withValues(alpha: 0.18);
    } else {
      color = Colors.white.withValues(alpha: hasSpend ? 0.42 : 0.14);
    }

    // Empty days get a small dot so the month's rhythm stays visible.
    final height = hasSpend ? math.max(6.0, fraction * 56) : 3.0;

    return Semantics(
      button: !isFuture,
      selected: isSelected,
      label:
          '${DateFormat('d MMMM').format(day)}: '
          '${hasSpend ? formatMad(cents) : 'nothing spent'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isFuture
            ? null
            : () {
                Haptics.selection();
                onTap(day);
              },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: isFuture ? 3 : height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: isFuture ? Colors.white.withValues(alpha: 0.06) : color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
