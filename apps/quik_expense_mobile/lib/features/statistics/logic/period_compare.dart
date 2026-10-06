import 'package:database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../shared/spending.dart';
import 'period_stats.dart';

/// One category in "this period vs the previous one" — including
/// categories used in only one of the two.
@immutable
class CategoryComparison {
  const CategoryComparison({
    required this.category,
    required this.currentCents,
    required this.previousCents,
  });

  final CategoryRow category;
  final int currentCents;
  final int previousCents;

  int get differenceCents => currentCents - previousCents;

  /// `null` when nothing was spent before (shown as "New").
  int? get deltaPercent => percentChange(currentCents, previousCents);
}

@immutable
class PeriodComparison {
  const PeriodComparison({
    required this.currentTotalCents,
    required this.previousTotalCents,
    required this.categories,
  });

  final int currentTotalCents;
  final int previousTotalCents;

  /// Biggest of the two amounts first.
  final List<CategoryComparison> categories;

  int get differenceCents => currentTotalCents - previousTotalCents;
  int? get deltaPercent => percentChange(currentTotalCents, previousTotalCents);
}

/// [expenses] must cover the window's load range (previous + current).
PeriodComparison comparePeriods(
  PeriodWindow window,
  List<ExpenseDetails> expenses,
) => compareExpenses(
  inRange(expenses, window.current),
  inRange(expenses, window.previous),
);

/// Compares two sets of expenses (this period vs any other one).
PeriodComparison compareExpenses(
  Iterable<ExpenseDetails> current,
  Iterable<ExpenseDetails> previous,
) {
  final rows = <String, (CategoryRow, int, int)>{};
  for (final e in current) {
    final (_, cur, prev) = rows[e.category.id] ?? (e.category, 0, 0);
    rows[e.category.id] = (e.category, cur + e.expense.amountCents, prev);
  }
  for (final e in previous) {
    final (_, cur, prev) = rows[e.category.id] ?? (e.category, 0, 0);
    rows[e.category.id] = (e.category, cur, prev + e.expense.amountCents);
  }

  int size(CategoryComparison c) =>
      c.currentCents > c.previousCents ? c.currentCents : c.previousCents;

  return PeriodComparison(
    currentTotalCents: sumCents(current),
    previousTotalCents: sumCents(previous),
    categories: [
      for (final (category, cur, prev) in rows.values)
        CategoryComparison(
          category: category,
          currentCents: cur,
          previousCents: prev,
        ),
    ]..sort((a, b) => size(b).compareTo(size(a))),
  );
}

/// How many of [period] fit before the current one in the picker (about
/// two years back).
int comparableCount(StatsPeriod period) => switch (period) {
  StatsPeriod.today => 730,
  StatsPeriod.week => 104,
  StatsPeriod.month => 24,
  StatsPeriod.sixMonths => 4,
  StatsPeriod.year => 2,
  StatsPeriod.all => 0,
};

/// The range [offset] periods before the current [window] (1 = previous).
/// Calendar arithmetic only, so DST never shifts a boundary.
DateRange shiftedRange(StatsPeriod period, PeriodWindow window, int offset) {
  final from = window.current.from;
  final to = window.current.to;
  DateTime days(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
  DateTime months(DateTime d, int n) => DateTime(d.year, d.month + n, d.day);
  return switch (period) {
    StatsPeriod.today => (from: days(from, -offset), to: days(to, -offset)),
    StatsPeriod.week => (
      from: days(from, -7 * offset),
      to: days(to, -7 * offset),
    ),
    StatsPeriod.month => (
      from: months(from, -offset),
      to: months(from, 1 - offset),
    ),
    StatsPeriod.sixMonths => (
      from: months(from, -6 * offset),
      to: months(to, -6 * offset),
    ),
    StatsPeriod.year => (
      from: months(from, -12 * offset),
      to: months(to, -12 * offset),
    ),
    StatsPeriod.all => window.current,
  };
}

/// Display name of a period range: "Today", "Yesterday", "Mon, Oct 5",
/// "This week", "Last week", "Sep 21 – Sep 27", "October",
/// "September 2025", "Nov 2024 – Oct 2025".
String rangeName(StatsPeriod period, DateRange range, DateTime now) {
  // Whole calendar days between two dates, immune to DST (23/25 h days).
  int daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  final last = DateTime(range.to.year, range.to.month, range.to.day - 1);
  final md = DateFormat.MMMd('en_US');
  final short = DateFormat.yMMM('en_US');
  switch (period) {
    case StatsPeriod.today:
      final diff = daysBetween(range.from, now);
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return DateFormat(
        range.from.year == now.year ? 'EEE, MMM d' : 'EEE, MMM d, y',
        'en_US',
      ).format(range.from);
    case StatsPeriod.week:
      final weeks = (daysBetween(range.from, now) / 7).floor();
      if (weeks == 0) return 'This week';
      if (weeks == 1) return 'Last week';
      return '${md.format(range.from)} – ${md.format(last)}';
    case StatsPeriod.month:
      return range.from.year == now.year
          ? DateFormat.MMMM('en_US').format(range.from)
          : DateFormat.yMMMM('en_US').format(range.from);
    case StatsPeriod.sixMonths:
    case StatsPeriod.year:
      return '${short.format(range.from)} – ${short.format(last)}';
    case StatsPeriod.all:
      return 'All time';
  }
}
