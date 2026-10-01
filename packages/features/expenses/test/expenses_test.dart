import 'package:flutter_test/flutter_test.dart';
import 'package:expenses/expenses.dart';

void main() {
  group('ExpensesState', () {
    test('initial state is ExpensesInitial', () {
      const state = ExpensesState.initial();
      expect(state, isA<ExpensesState>());
    });
  });
}
