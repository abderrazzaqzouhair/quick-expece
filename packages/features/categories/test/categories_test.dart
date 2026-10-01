import 'package:flutter_test/flutter_test.dart';
import 'package:categories/categories.dart';

void main() {
  group('CategoriesState', () {
    test('initial state is CategoriesInitial', () {
      const state = CategoriesState.initial();
      expect(state, isA<CategoriesState>());
    });
  });
}
