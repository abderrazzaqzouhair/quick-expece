import 'package:database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/providers/database_providers.dart';

/// Half-open date range: [from] inclusive, [to] exclusive. A record, so it
/// has value equality and works as a provider family key.
typedef DateRange = ({DateTime from, DateTime to});

/// Live expenses in a range, newest first.
final expensesInRangeProvider =
    StreamProvider.family<List<ExpenseDetails>, DateRange>(
      (ref, range) => ref
          .watch(appDatabaseProvider)
          .expensesDao
          .watchDetails(from: range.from, to: range.to),
    );

/// The latest few expenses, across all time.
final recentExpensesProvider = StreamProvider<List<ExpenseDetails>>(
  (ref) => ref.watch(appDatabaseProvider).expensesDao.watchDetails(limit: 4),
);

/// What was spent on one category, optionally vs a previous period.
@immutable
class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.totalCents,
    this.previousCents = 0,
  });

  final CategoryRow category;
  final int totalCents;
  final int previousCents;

  /// Signed % change vs the previous period; `null` when there was nothing
  /// to compare against (show "New" instead of a misleading +∞%).
  int? get deltaPercent => percentChange(totalCents, previousCents);
}

/// Signed whole-percent change, or `null` when [previous] is zero.
int? percentChange(int current, int previous) {
  if (previous == 0) return null;
  return ((current - previous) / previous * 100).round();
}

bool _inRange(DateTime date, DateRange range) =>
    !date.isBefore(range.from) && date.isBefore(range.to);

int sumCents(Iterable<ExpenseDetails> expenses) =>
    expenses.fold(0, (sum, e) => sum + e.expense.amountCents);

/// Expenses whose date falls in [range].
Iterable<ExpenseDetails> inRange(
  Iterable<ExpenseDetails> expenses,
  DateRange range,
) => expenses.where((e) => _inRange(e.expense.date, range));

/// Per-category totals for [current] (biggest first), with each category's
/// total in [previous] attached for the trend. Categories only present in
/// [previous] are omitted — nothing was spent on them now.
List<CategorySpend> categoryTotals(
  Iterable<ExpenseDetails> current, {
  Iterable<ExpenseDetails> previous = const [],
}) {
  final now = <String, (CategoryRow, int)>{};
  for (final e in current) {
    final (_, cents) = now[e.category.id] ?? (e.category, 0);
    now[e.category.id] = (e.category, cents + e.expense.amountCents);
  }
  final before = <String, int>{};
  for (final e in previous) {
    before.update(
      e.category.id,
      (c) => c + e.expense.amountCents,
      ifAbsent: () => e.expense.amountCents,
    );
  }
  return [
    for (final MapEntry(key: id, value: (category, cents)) in now.entries)
      CategorySpend(
        category: category,
        totalCents: cents,
        previousCents: before[id] ?? 0,
      ),
  ]..sort((a, b) => b.totalCents.compareTo(a.totalCents));
}
