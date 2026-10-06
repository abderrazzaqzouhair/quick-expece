import 'package:database/database.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/formatters.dart';
import '../../../shared/spending.dart';
import 'period_stats.dart';

/// A subcategory's spend in the period.
@immutable
class SubcategorySpend {
  const SubcategorySpend({
    required this.category,
    required this.subcategory,
    required this.totalCents,
    required this.count,
  });

  final CategoryRow category;
  final SubcategoryRow subcategory;
  final int totalCents;
  final int count;
}

/// The extra sections under the trend chart: top subcategories, habits
/// (counts, weekday pattern) and the largest single expenses.
@immutable
class PeriodDetails {
  const PeriodDetails({
    required this.topSubcategories,
    required this.largest,
    required this.count,
    required this.averageExpenseCents,
    required this.elapsedDays,
    required this.noSpendDays,
    required this.mostFrequent,
    required this.weekdayAverages,
  });

  /// Biggest spend first (max 5).
  final List<SubcategorySpend> topSubcategories;

  /// Biggest single expenses first (max 5).
  final List<ExpenseDetails> largest;

  final int count;
  final int averageExpenseCents;

  /// Days of the period that have started, and how many had no spending.
  final int elapsedDays;
  final int noSpendDays;

  /// Most used subcategory (by number of expenses), if any.
  final SubcategorySpend? mostFrequent;

  /// Average spend per weekday occurrence, Monday first (cents). A Saturday
  /// average of 50.00 means "on a typical Saturday you spend 50.00".
  final List<int> weekdayAverages;

  /// Index (0 = Monday) of the weekday with the highest average, or `null`
  /// when fewer than two weekdays have any spending (no real pattern).
  int? get topWeekday {
    final withSpend = weekdayAverages.where((c) => c > 0).length;
    if (withSpend < 2) return null;
    var best = 0;
    for (var i = 1; i < 7; i++) {
      if (weekdayAverages[i] > weekdayAverages[best]) best = i;
    }
    return best;
  }
}

/// [expenses] must cover the window's load range.
PeriodDetails buildPeriodDetails(
  StatsPeriod period,
  PeriodWindow window,
  List<ExpenseDetails> expenses,
  DateTime now,
) {
  final current = inRange(expenses, window.current).toList();

  // Subcategory totals and counts.
  final bySub = <String, SubcategorySpend>{};
  for (final e in current) {
    final prev = bySub[e.subcategory.id];
    bySub[e.subcategory.id] = SubcategorySpend(
      category: e.category,
      subcategory: e.subcategory,
      totalCents: (prev?.totalCents ?? 0) + e.expense.amountCents,
      count: (prev?.count ?? 0) + 1,
    );
  }
  final subs = bySub.values.toList();
  final top = [...subs]..sort((a, b) => b.totalCents.compareTo(a.totalCents));
  final frequent = [...subs]
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : b.totalCents.compareTo(a.totalCents);
    });

  final largest = [...current]
    ..sort((a, b) => b.expense.amountCents.compareTo(a.expense.amountCents));

  // Elapsed days: from the period start (or the first expense, for All)
  // through today, capped at the period end.
  final today = dateOnly(now);
  final firstDay = period == StatsPeriod.all
      ? (current.isEmpty
            ? today
            : current
                  .map((e) => dateOnly(e.expense.date))
                  .reduce((a, b) => a.isBefore(b) ? a : b))
      : dateOnly(window.current.from);
  final endExclusive = dateOnly(window.current.to);
  final lastDay = today.isBefore(endExclusive)
      ? today
      : DateTime(endExclusive.year, endExclusive.month, endExclusive.day - 1);

  final days = <DateTime>[];
  for (
    var d = firstDay;
    !d.isAfter(lastDay);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    days.add(d);
  }
  final spendDays = {for (final e in current) dateOnly(e.expense.date)};

  // Weekday averages over the elapsed days.
  final weekdayTotals = List<int>.filled(7, 0);
  final weekdayCounts = List<int>.filled(7, 0);
  for (final d in days) {
    weekdayCounts[d.weekday - 1]++;
  }
  for (final e in current) {
    weekdayTotals[e.expense.date.weekday - 1] += e.expense.amountCents;
  }

  final total = sumCents(current);
  return PeriodDetails(
    topSubcategories: top.take(5).toList(),
    largest: largest.take(5).toList(),
    count: current.length,
    averageExpenseCents: current.isEmpty ? 0 : total ~/ current.length,
    elapsedDays: days.length,
    noSpendDays: days.where((d) => !spendDays.contains(d)).length,
    mostFrequent: frequent.isEmpty ? null : frequent.first,
    weekdayAverages: [
      for (var i = 0; i < 7; i++)
        weekdayCounts[i] == 0 ? 0 : weekdayTotals[i] ~/ weekdayCounts[i],
    ],
  );
}
