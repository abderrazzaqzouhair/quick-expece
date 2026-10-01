import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/profile_entity.dart';

part 'profile_state.freezed.dart';

/// Freezed sealed union consumed by the presentation layer (screens/widgets)
/// via `profileControllerProvider`.
@freezed
sealed class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = ProfileInitial;

  const factory ProfileState.loading() = ProfileLoading;

  const factory ProfileState.success(List<ProfileEntity> items) =
      ProfileSuccess;

  const factory ProfileState.failure(String message) = ProfileFailure;
}
