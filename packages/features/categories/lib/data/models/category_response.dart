import 'package:freezed_annotation/freezed_annotation.dart';

import 'subcategory_response.dart';

part 'category_response.freezed.dart';
part 'category_response.g.dart';

/// Mirrors `App\Http\Resources\CategoryResource` on the Laravel backend.
@freezed
abstract class CategoryResponse with _$CategoryResponse {
  const factory CategoryResponse({
    required int id,
    required String name,
    String? icon,
    @JsonKey(name: 'icon_url') String? iconUrl,
    required String color,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'subcategories_count') int? subcategoriesCount,
    @Default([]) List<SubcategoryResponse> subcategories,
  }) = _CategoryResponse;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryResponseFromJson(json);
}
