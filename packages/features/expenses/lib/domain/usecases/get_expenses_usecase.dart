import '../entities/expenses_entity.dart';
import '../repositories/expenses_repository.dart';

/// Single-purpose callable — one business operation per usecase. Add more
/// (`CreateExpensesUseCase`, `Delete...`, etc.) following this shape.
class GetExpensesUseCase {
  const GetExpensesUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<List<ExpensesEntity>> call() => _repository.getAll();
}
