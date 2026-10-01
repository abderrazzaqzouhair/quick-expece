import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

/// Raw API DTO — mirrors the JSON shape returned by the backend. Mapped onto
/// `AuthEntity` in `data/mappers`.
@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({required String id}) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
