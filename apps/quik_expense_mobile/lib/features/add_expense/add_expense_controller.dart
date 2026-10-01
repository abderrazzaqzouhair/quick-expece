import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/providers/database_providers.dart';
import 'logic/amount_entry.dart';

/// What the user still has to do before the expense can be saved — drives
/// the save button's label and what tapping it does.
enum AddExpenseStep { enterAmount, chooseCategory, ready }

@immutable
class AddExpenseState {
  const AddExpenseState({
    required this.day,
    this.amountText = '',
    this.category,
    this.subcategory,
    this.note = '',
    this.isSaving = false,
  });

  /// Raw keypad text, e.g. `"42.5"` (see [AmountEntry]).
  final String amountText;
  final CategoryRow? category;
  final SubcategoryRow? subcategory;

  /// The day the expense happened (date only — see [expenseDate]).
  final DateTime day;
  final String note;
  final bool isSaving;

  int? get amountCents => Money.parseCents(amountText);

  bool get isAmountValid {
    final cents = amountCents;
    return cents != null && cents > 0 && cents <= Money.maxCents;
  }

  AddExpenseStep get step {
    if (!isAmountValid) return AddExpenseStep.enterAmount;
    if (subcategory == null) return AddExpenseStep.chooseCategory;
    return AddExpenseStep.ready;
  }

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

  AddExpenseState copyWith({
    String? amountText,
    CategoryRow? category,
    SubcategoryRow? subcategory,
    DateTime? day,
    String? note,
    bool? isSaving,
  }) => AddExpenseState(
    amountText: amountText ?? this.amountText,
    category: category ?? this.category,
    subcategory: subcategory ?? this.subcategory,
    day: day ?? this.day,
    note: note ?? this.note,
    isSaving: isSaving ?? this.isSaving,
  );
}

final addExpenseControllerProvider =
    NotifierProvider.autoDispose<AddExpenseController, AddExpenseState>(
      AddExpenseController.new,
    );

class AddExpenseController extends Notifier<AddExpenseState> {
  @override
  AddExpenseState build() {
    final now = DateTime.now();
    return AddExpenseState(day: DateTime(now.year, now.month, now.day));
  }

  /// Applies a keypad press. Returns `false` if the key was rejected (the
  /// screen shakes the amount).
  bool pressKey(AmountKey key) {
    final next = AmountEntry.press(state.amountText, key);
    if (next == null) return false;
    state = state.copyWith(amountText: next);
    return true;
  }

  void clearAmount() => state = state.copyWith(amountText: '');

  void selectSubcategory(CategoryRow category, SubcategoryRow subcategory) =>
      state = state.copyWith(category: category, subcategory: subcategory);

  void selectDay(DateTime day) =>
      state = state.copyWith(day: DateTime(day.year, day.month, day.day));

  void setNote(String note) => state = state.copyWith(note: note.trim());

  /// Saves the expense. Returns `true` on success; throws on a database
  /// error (the screen shows it).
  Future<bool> save() async {
    final current = state;
    if (current.step != AddExpenseStep.ready || current.isSaving) return false;
    state = current.copyWith(isSaving: true);
    try {
      await ref
          .read(appDatabaseProvider)
          .expensesDao
          .add(
            subcategoryId: current.subcategory!.id,
            amountCents: current.amountCents!,
            date: current.expenseDate,
            note: current.note.isEmpty ? null : current.note,
          );
      return true;
    } finally {
      if (ref.mounted) state = state.copyWith(isSaving: false);
    }
  }
}
