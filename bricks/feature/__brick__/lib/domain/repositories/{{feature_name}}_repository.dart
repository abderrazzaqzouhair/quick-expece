import '../entities/{{feature_name}}_entity.dart';

/// Abstract contract consumed by usecases. Implemented by
/// `{{#pascalCase}}{{feature_name}}{{/pascalCase}}RepositoryImpl` in `data/repositories`.
///
/// Throws a `core` `Failure` on error — never a networking-layer exception —
/// so `domain`/`presentation` stay decoupled from the networking package.
abstract interface class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository {
  Future<List<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity>> getAll();
}
