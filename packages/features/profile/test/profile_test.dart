import 'package:flutter_test/flutter_test.dart';
import 'package:profile/profile.dart';

void main() {
  group('ProfileState', () {
    test('initial state is ProfileInitial', () {
      const state = ProfileState.initial();
      expect(state, isA<ProfileState>());
    });
  });
}
