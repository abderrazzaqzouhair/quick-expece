import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/expenses_entity.dart';

part 'expenses_state.freezed.dart';

/// Freezed sealed union consumed by the presentation layer (screens/widgets)
/// via `expensesControllerProvider`.
@freezed
sealed class ExpensesState with _$ExpensesState {
  const factory ExpensesState.initial() = ExpensesInitial;

  const factory ExpensesState.loading() = ExpensesLoading;

  const factory ExpensesState.success(List<ExpensesEntity> items) =
      ExpensesSuccess;

  const factory ExpensesState.failure(String message) = ExpensesFailure;
}
