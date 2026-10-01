import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

/// Single-purpose callable — one business operation per usecase. Add more
/// (`ActivateCategoryUseCase`, `DeactivateCategoryUseCase`, etc.) following
/// this shape.
class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<List<CategoryEntity>> call() => _repository.getAll();
}
