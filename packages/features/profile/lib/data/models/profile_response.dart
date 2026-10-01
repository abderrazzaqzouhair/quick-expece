import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_response.freezed.dart';
part 'profile_response.g.dart';

/// Raw API DTO — mirrors the JSON shape returned by the backend. Mapped onto
/// `ProfileEntity` in `data/mappers`.
@freezed
abstract class ProfileResponse with _$ProfileResponse {
  const factory ProfileResponse({required String id}) = _ProfileResponse;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}
