import 'package:flutter_test/flutter_test.dart';
import 'package:auth/auth.dart';

void main() {
  group('AuthState', () {
    test('initial state is AuthInitial', () {
      const state = AuthState.initial();
      expect(state, isA<AuthState>());
    });
  });
}
