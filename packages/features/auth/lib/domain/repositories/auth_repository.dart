import '../entities/auth_entity.dart';

/// Abstract contract consumed by usecases. Implemented by
/// `AuthRepositoryImpl` in `data/repositories`.
///
/// Throws a `core` `Failure` on error — never a networking-layer exception —
/// so `domain`/`presentation` stay decoupled from the networking package.
abstract interface class AuthRepository {
  Future<List<AuthEntity>> getAll();
}
