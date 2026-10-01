import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/category_entity.dart';

part 'categories_state.freezed.dart';

/// Freezed sealed union consumed by the presentation layer (screens/widgets)
/// via `categoriesControllerProvider`.
@freezed
sealed class CategoriesState with _$CategoriesState {
  const factory CategoriesState.initial() = CategoriesInitial;

  const factory CategoriesState.loading() = CategoriesLoading;

  const factory CategoriesState.success(List<CategoryEntity> items) =
      CategoriesSuccess;

  const factory CategoriesState.failure(String message) = CategoriesFailure;
}
