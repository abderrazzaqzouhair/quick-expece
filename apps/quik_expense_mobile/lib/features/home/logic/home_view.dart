import 'package:database/database.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/formatters.dart';
import '../../../shared/spending.dart';

/// The month containing [date], and the one before it — Home loads both so
/// category cards can show a trend vs last month.
DateRange homeDataRange(DateTime date) => (
  from: DateTime(date.year, date.month - 1),
  to: DateTime(date.year, date.month + 1),
);

/// Monday-first calendar grid for [month], padded with adjacent-month days
/// so every row is a full week.
List<DateTime> calendarGrid(DateTime month) {
  final first = DateTime(month.year, month.month);
  final last = DateTime(month.year, month.month + 1, 0);
  // Calendar arithmetic, not Duration — Duration math drifts an hour across
  // DST changes.
  final start = DateTime(first.year, first.month, 1 - (first.weekday - 1));
  final cells = ((last.day + first.weekday - 1) / 7).ceil() * 7;
  return [
    for (var i = 0; i < cells; i++)
      DateTime(start.year, start.month, start.day + i),
  ];
}

/// What the Home dashboard shows for [selectedDate].
@immutable
class HomeView {
  const HomeView({
    required this.dayTotalCents,
    required this.monthTotalCents,
    required this.categories,
  });

  /// `null` when nothing was spent that day (shown as "No expenses").
  final int? dayTotalCents;

  /// `null` when nothing was spent that month.
  final int? monthTotalCents;

  /// The selected month's categories, biggest first, with trend vs the
  /// previous month.
  final List<CategorySpend> categories;
}

/// [expenses] must cover [homeDataRange] of [selectedDate].
HomeView buildHomeView(List<ExpenseDetails> expenses, DateTime selectedDate) {
  final day = dateOnly(selectedDate);
  final monthStart = DateTime(day.year, day.month);
  final thisMonth = inRange(expenses, (
    from: monthStart,
    to: DateTime(day.year, day.month + 1),
  )).toList();
  final lastMonth = inRange(expenses, (
    from: DateTime(day.year, day.month - 1),
    to: monthStart,
  ));
  final today = thisMonth.where((e) => dateOnly(e.expense.date) == day);

  return HomeView(
    dayTotalCents: today.isEmpty ? null : sumCents(today),
    monthTotalCents: thisMonth.isEmpty ? null : sumCents(thisMonth),
    categories: categoryTotals(thisMonth, previous: lastMonth),
  );
}

/// Days (date-only) in [expenses] that have at least one expense — the
/// calendar's activity dots.
Set<DateTime> daysWithSpend(Iterable<ExpenseDetails> expenses) => {
  for (final e in expenses) dateOnly(e.expense.date),
};
