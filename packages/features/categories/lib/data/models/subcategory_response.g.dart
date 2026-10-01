// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subcategory_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubcategoryResponse _$SubcategoryResponseFromJson(Map<String, dynamic> json) =>
    _SubcategoryResponse(
      id: (json['id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      name: json['name'] as String,
      icon: json['icon'] as String?,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$SubcategoryResponseToJson(
  _SubcategoryResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'category_id': instance.categoryId,
  'name': instance.name,
  'icon': instance.icon,
  'icon_url': instance.iconUrl,
  'is_active': instance.isActive,
};
