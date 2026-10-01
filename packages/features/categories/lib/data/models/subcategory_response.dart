import 'package:freezed_annotation/freezed_annotation.dart';

part 'subcategory_response.freezed.dart';
part 'subcategory_response.g.dart';

/// Mirrors `App\Http\Resources\SubcategoryResource` on the Laravel backend.
@freezed
abstract class SubcategoryResponse with _$SubcategoryResponse {
  const factory SubcategoryResponse({
    required int id,
    @JsonKey(name: 'category_id') required int categoryId,
    required String name,
    String? icon,
    @JsonKey(name: 'icon_url') String? iconUrl,
    @JsonKey(name: 'is_active') required bool isActive,
  }) = _SubcategoryResponse;

  factory SubcategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$SubcategoryResponseFromJson(json);
}
