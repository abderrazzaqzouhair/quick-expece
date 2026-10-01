import '../entities/expenses_entity.dart';

/// Abstract contract consumed by usecases. Implemented by
/// `ExpensesRepositoryImpl` in `data/repositories`.
///
/// Throws a `core` `Failure` on error — never a networking-layer exception —
/// so `domain`/`presentation` stay decoupled from the networking package.
abstract interface class ExpensesRepository {
  Future<List<ExpensesEntity>> getAll();
}
