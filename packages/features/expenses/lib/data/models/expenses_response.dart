import 'package:freezed_annotation/freezed_annotation.dart';

part 'expenses_response.freezed.dart';
part 'expenses_response.g.dart';

/// Raw API DTO — mirrors the JSON shape returned by the backend. Mapped onto
/// `ExpensesEntity` in `data/mappers`.
@freezed
abstract class ExpensesResponse with _$ExpensesResponse {
  const factory ExpensesResponse({required String id}) = _ExpensesResponse;

  factory ExpensesResponse.fromJson(Map<String, dynamic> json) =>
      _$ExpensesResponseFromJson(json);
}
