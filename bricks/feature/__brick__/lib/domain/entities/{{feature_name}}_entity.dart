import 'package:equatable/equatable.dart';

/// Plain domain entity — no JSON/Freezed coupling. Add fields as the
/// `{{feature_name}}` domain takes shape.
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity extends Equatable {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Entity({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
