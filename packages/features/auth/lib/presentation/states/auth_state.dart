import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_entity.dart';

part 'auth_state.freezed.dart';

/// Freezed sealed union consumed by the presentation layer (screens/widgets)
/// via `authControllerProvider`.
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;

  const factory AuthState.loading() = AuthLoading;

  const factory AuthState.success(List<AuthEntity> items) = AuthSuccess;

  const factory AuthState.failure(String message) = AuthFailure;
}
