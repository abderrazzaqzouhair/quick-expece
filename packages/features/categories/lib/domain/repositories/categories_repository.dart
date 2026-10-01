import '../entities/category_entity.dart';

/// Abstract contract consumed by usecases. Implemented by
/// `CategoriesRepositoryImpl` in `data/repositories`.
///
/// Throws a `core` `Failure` on error — never a networking-layer exception —
/// so `domain`/`presentation` stay decoupled from the networking package.
abstract interface class CategoriesRepository {
  Future<List<CategoryEntity>> getAll();
}
