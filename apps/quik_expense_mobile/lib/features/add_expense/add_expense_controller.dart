import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/providers/database_providers.dart';

/// Form state of the add-expense screen. Only the parts that drive the UI
/// live here — the note stays in its `TextEditingController` and is passed
/// to [AddExpenseController.save].
@immutable
class AddExpenseState {
  const AddExpenseState({
    required this.day,
    this.amountCents,
    this.categoryId,
    this.subcategoryId,
    this.isSaving = false,
  });

  /// `null` while the amount field is empty or invalid.
  final int? amountCents;
  final String? categoryId;
  final String? subcategoryId;

  /// The day the expense happened (time part ignored — see [expenseDate]).
  final DateTime day;
  final bool isSaving;

  static const _unset = Object();

  /// Nullable fields use a sentinel so they can be explicitly cleared:
  /// `copyWith(subcategoryId: null)`.
  AddExpenseState copyWith({
    Object? amountCents = _unset,
    Object? categoryId = _unset,
    Object? subcategoryId = _unset,
    DateTime? day,
    bool? isSaving,
  }) => AddExpenseState(
    amountCents: identical(amountCents, _unset)
        ? this.amountCents
        : amountCents as int?,
    categoryId: identical(categoryId, _unset)
        ? this.categoryId
        : categoryId as String?,
    subcategoryId: identical(subcategoryId, _unset)
        ? this.subcategoryId
        : subcategoryId as String?,
    day: day ?? this.day,
    isSaving: isSaving ?? this.isSaving,
  );

  bool get isAmountValid =>
      amountCents != null && amountCents! > 0 && amountCents! <= Money.maxCents;

  bool get canSave => isAmountValid && subcategoryId != null && !isSaving;

  /// [day] with the current time of day, so expenses added the same day keep
  /// their order in lists.
  DateTime get expenseDate {
    final now = DateTime.now();
    return DateTime(
      day.year,
      day.month,
      day.day,
      now.hour,
      now.minute,
      now.second,
    );
  }
}

final addExpenseControllerProvider =
    NotifierProvider.autoDispose<AddExpenseController, AddExpenseState>(
      AddExpenseController.new,
    );

class AddExpenseController extends Notifier<AddExpenseState> {
  @override
  AddExpenseState build() => AddExpenseState(day: _today());

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setAmount(String input) =>
      state = state.copyWith(amountCents: Money.parseCents(input));

  /// Changing the category clears the subcategory — it belonged to the old
  /// one. Tapping the selected category again keeps it.
  void selectCategory(String categoryId) {
    if (categoryId == state.categoryId) return;
    state = state.copyWith(categoryId: categoryId, subcategoryId: null);
  }

  void selectSubcategory(String subcategoryId) =>
      state = state.copyWith(subcategoryId: subcategoryId);

  void selectDay(DateTime day) =>
      state = state.copyWith(day: DateTime(day.year, day.month, day.day));

  /// Saves the expense. Returns `true` on success; throws on a database
  /// error (the screen shows it).
  Future<bool> save({String? note}) async {
    if (!state.canSave) return false;
    final current = state;
    state = current.copyWith(isSaving: true);
    try {
      final trimmed = note?.trim();
      await ref
          .read(appDatabaseProvider)
          .expensesDao
          .add(
            subcategoryId: current.subcategoryId!,
            amountCents: current.amountCents!,
            date: current.expenseDate,
            note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
          );
      return true;
    } finally {
      if (ref.mounted) state = state.copyWith(isSaving: false);
    }
  }
}
