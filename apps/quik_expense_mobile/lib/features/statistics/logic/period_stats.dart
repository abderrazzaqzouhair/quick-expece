import 'package:database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../shared/spending.dart';

enum StatsPeriod {
  today('Today', 'Avg Spend'),
  week('Week', 'Daily Avg'),
  month('Month', 'Weekly Avg'),
  sixMonths('6M', 'Monthly Avg'),
  year('Year', 'Monthly Avg'),
  all('All', 'Yearly Avg');

  const StatsPeriod(this.label, this.averageLabel);
  final String label;
  final String averageLabel;
}

/// One bar of the trend chart.
@immutable
class StatsBucket {
  const StatsBucket({
    required this.label,
    required this.range,
    this.totalCents = 0,
  });

  final String label;
  final DateRange range;
  final int totalCents;

  bool isCurrent(DateTime now) =>
      !now.isBefore(range.from) && now.isBefore(range.to);
  bool isFuture(DateTime now) => range.from.isAfter(now);

  StatsBucket withTotal(int cents) =>
      StatsBucket(label: label, range: range, totalCents: cents);
}

/// The time window a period covers, its comparison window, and its buckets.
@immutable
class PeriodWindow {
  const PeriodWindow({
    required this.current,
    required this.previous,
    required this.buckets,
  });

  final DateRange current;

  /// Same length, immediately before [current].
  final DateRange previous;
  final List<StatsBucket> buckets;

  /// Everything to load: previous + current.
  DateRange get loadRange => (from: previous.from, to: current.to);
}

/// Windows (all calendar-aligned, Monday-first weeks):
/// - week: this Mon–Sun, one bar per day;
/// - month: this calendar month, bars for days 1–7, 8–14, 15–21, 22–28, 29+;
/// - 6M / year: the last 6 / 12 months including this one, a bar per month.
PeriodWindow windowFor(StatsPeriod period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  switch (period) {
    case StatsPeriod.today:
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      // Fixed quarters rather than hourly buckets — readable on the trend
      // chart and still gives a sense of when today's spending happened.
      const labels = ['Night', 'Morning', 'Afternoon', 'Evening'];
      return PeriodWindow(
        current: (from: today, to: tomorrow),
        previous: (from: yesterday, to: today),
        buckets: [
          for (var i = 0; i < 4; i++)
            StatsBucket(
              label: labels[i],
              range: (
                from: DateTime(today.year, today.month, today.day, i * 6),
                to: DateTime(today.year, today.month, today.day, i * 6 + 6),
              ),
            ),
        ],
      );

    case StatsPeriod.week:
      final monday = DateTime(
        today.year,
        today.month,
        today.day - (today.weekday - 1),
      );
      final days = [
        for (var i = 0; i < 7; i++)
          DateTime(monday.year, monday.month, monday.day + i),
      ];
      return PeriodWindow(
        current: (
          from: monday,
          to: DateTime(monday.year, monday.month, monday.day + 7),
        ),
        previous: (
          from: DateTime(monday.year, monday.month, monday.day - 7),
          to: monday,
        ),
        buckets: [
          for (final d in days)
            StatsBucket(
              label: DateFormat.E('en_US').format(d),
              range: (from: d, to: DateTime(d.year, d.month, d.day + 1)),
            ),
        ],
      );

    case StatsPeriod.month:
      final start = DateTime(today.year, today.month);
      final end = DateTime(today.year, today.month + 1);
      final buckets = <StatsBucket>[];
      for (
        var day = 1, week = 1;
        day <= DateTime(start.year, start.month + 1, 0).day;
        day += 7, week++
      ) {
        final from = DateTime(start.year, start.month, day);
        final to = week == 5 ? end : DateTime(start.year, start.month, day + 7);
        buckets.add(
          StatsBucket(
            label: 'W$week',
            range: (from: from, to: to.isAfter(end) ? end : to),
          ),
        );
      }
      return PeriodWindow(
        current: (from: start, to: end),
        previous: (from: DateTime(today.year, today.month - 1), to: start),
        buckets: buckets,
      );

    case StatsPeriod.all:
      // The span isn't known until the data loads (see `_yearBuckets` in
      // `buildPeriodStats`) — this window just needs to load everything,
      // with no "previous period" to compare against.
      final epoch = DateTime(2000);
      return PeriodWindow(
        current: (
          from: epoch,
          to: DateTime(today.year, today.month, today.day + 1),
        ),
        previous: (from: epoch, to: epoch),
        buckets: const [],
      );

    case StatsPeriod.sixMonths:
    case StatsPeriod.year:
      final count = period == StatsPeriod.year ? 12 : 6;
      final start = DateTime(today.year, today.month - (count - 1));
      return PeriodWindow(
        current: (from: start, to: DateTime(today.year, today.month + 1)),
        previous: (from: DateTime(start.year, start.month - count), to: start),
        buckets: [
          for (var i = 0; i < count; i++)
            StatsBucket(
              label: DateFormat.MMM(
                'en_US',
              ).format(DateTime(start.year, start.month + i)),
              range: (
                from: DateTime(start.year, start.month + i),
                to: DateTime(start.year, start.month + i + 1),
              ),
            ),
        ],
      );
  }
}

/// Everything the Statistics screen renders for one period.
@immutable
class PeriodStats {
  const PeriodStats({
    required this.period,
    required this.buckets,
    required this.totalCents,
    required this.previousTotalCents,
    required this.averageCents,
    required this.categories,
    required this.now,
  });

  final StatsPeriod period;
  final List<StatsBucket> buckets;
  final int totalCents;
  final int previousTotalCents;

  /// Total divided by the buckets that have started (so a half-elapsed
  /// month isn't diluted by its future weeks).
  final int averageCents;
  final List<CategorySpend> categories;
  final DateTime now;

  bool get isEmpty => totalCents == 0;

  int? get deltaPercent => percentChange(totalCents, previousTotalCents);

  List<StatsBucket> get elapsedBuckets =>
      buckets.where((b) => !b.isFuture(now)).toList();

  StatsBucket? get highest => elapsedBuckets.isEmpty
      ? null
      : elapsedBuckets.reduce((a, b) => b.totalCents > a.totalCents ? b : a);

  StatsBucket? get lowest => elapsedBuckets.isEmpty
      ? null
      : elapsedBuckets.reduce((a, b) => b.totalCents < a.totalCents ? b : a);
}

/// [expenses] must cover [PeriodWindow.loadRange].
PeriodStats buildPeriodStats(
  StatsPeriod period,
  PeriodWindow window,
  List<ExpenseDetails> expenses,
  DateTime now,
) {
  final current = inRange(expenses, window.current).toList();
  final previous = inRange(expenses, window.previous);
  final buckets = period == StatsPeriod.all
      ? _yearBuckets(current, now)
      : [
          for (final b in window.buckets)
            b.withTotal(sumCents(inRange(current, b.range))),
        ];
  final total = sumCents(current);
  final elapsed = buckets.where((b) => !b.isFuture(now)).length;

  return PeriodStats(
    period: period,
    buckets: buckets,
    totalCents: total,
    previousTotalCents: sumCents(previous),
    averageCents: elapsed == 0 ? 0 : total ~/ elapsed,
    categories: categoryTotals(current, previous: previous),
    now: now,
  );
}

/// One bar per calendar year from the earliest expense through [now]. Only
/// used for [StatsPeriod.all], whose span (unlike the other periods' fixed
/// calendar windows) isn't known until the data is actually loaded.
List<StatsBucket> _yearBuckets(List<ExpenseDetails> expenses, DateTime now) {
  final startYear = expenses.isEmpty
      ? now.year
      : expenses
            .map((e) => e.expense.date.year)
            .reduce((a, b) => a < b ? a : b);
  return [
    for (var year = startYear; year <= now.year; year++)
      StatsBucket(
        label: '$year',
        range: (from: DateTime(year), to: DateTime(year + 1)),
      ).withTotal(
        sumCents(
          inRange(expenses, (from: DateTime(year), to: DateTime(year + 1))),
        ),
      ),
  ];
}
