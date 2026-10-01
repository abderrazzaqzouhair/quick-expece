import 'package:flutter_test/flutter_test.dart';
import 'package:{{feature_name}}/{{feature_name}}.dart';

void main() {
  group('{{#pascalCase}}{{feature_name}}{{/pascalCase}}State', () {
    test('initial state is {{#pascalCase}}{{feature_name}}{{/pascalCase}}Initial', () {
      const state = {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.initial();
      expect(state, isA<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State>());
    });
  });
}
