import 'package:freezed_annotation/freezed_annotation.dart';

part '{{feature_name}}_response.freezed.dart';
part '{{feature_name}}_response.g.dart';

/// Raw API DTO — mirrors the JSON shape returned by the backend. Mapped onto
/// `{{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity` in `data/mappers`.
@freezed
abstract class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Response with _${{#pascalCase}}{{feature_name}}{{/pascalCase}}Response {
  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Response({
    required String id,
  }) = _{{#pascalCase}}{{feature_name}}{{/pascalCase}}Response;

  factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Response.fromJson(Map<String, dynamic> json) =>
      _${{#pascalCase}}{{feature_name}}{{/pascalCase}}ResponseFromJson(json);
}
