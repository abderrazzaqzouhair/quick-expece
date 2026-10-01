import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/{{feature_name}}_entity.dart';

part '{{feature_name}}_state.freezed.dart';

/// Freezed sealed union consumed by the presentation layer (screens/widgets)
/// via `{{#camelCase}}{{feature_name}}{{/camelCase}}ControllerProvider`.
@freezed
sealed class {{#pascalCase}}{{feature_name}}{{/pascalCase}}State with _${{#pascalCase}}{{feature_name}}{{/pascalCase}}State {
  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.initial() = {{#pascalCase}}{{feature_name}}{{/pascalCase}}Initial;

  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.loading() = {{#pascalCase}}{{feature_name}}{{/pascalCase}}Loading;

  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.success(
    List<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity> items,
  ) = {{#pascalCase}}{{feature_name}}{{/pascalCase}}Success;

  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.failure(String message) = {{#pascalCase}}{{feature_name}}{{/pascalCase}}Failure;
}
