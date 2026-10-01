import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

/// Single-purpose callable — one business operation per usecase. Add more
/// (`CreateProfileUseCase`, `Delete...`, etc.) following this shape.
class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<List<ProfileEntity>> call() => _repository.getAll();
}
