import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

/// Single-purpose callable — one business operation per usecase. Add more
/// (`CreateAuthUseCase`, `Delete...`, etc.) following this shape.
class GetAuthUseCase {
  const GetAuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<List<AuthEntity>> call() => _repository.getAll();
}
