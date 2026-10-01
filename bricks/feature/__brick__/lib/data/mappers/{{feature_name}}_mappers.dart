import '../../domain/entities/{{feature_name}}_entity.dart';
import '../models/{{feature_name}}_response.dart';

/// DTO -> domain entity mapping. Keep all shape-translation here so
/// `RepositoryImpl` stays focused on orchestration.
extension {{#pascalCase}}{{feature_name}}{{/pascalCase}}ResponseMapper on {{#pascalCase}}{{feature_name}}{{/pascalCase}}Response {
  {{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity toEntity() => {{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity(id: id);
}
