import '../entities/{{feature_name}}_entity.dart';
import '../repositories/{{feature_name}}_repository.dart';

/// Single-purpose callable — one business operation per usecase. Add more
/// (`Create{{#pascalCase}}{{feature_name}}{{/pascalCase}}UseCase`, `Delete...`, etc.) following this shape.
class Get{{#pascalCase}}{{feature_name}}{{/pascalCase}}UseCase {
  const Get{{#pascalCase}}{{feature_name}}{{/pascalCase}}UseCase(this._repository);

  final {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository _repository;

  Future<List<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity>> call() => _repository.getAll();
}
