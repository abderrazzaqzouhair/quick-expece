// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryResponse _$CategoryResponseFromJson(Map<String, dynamic> json) =>
    _CategoryResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      icon: json['icon'] as String?,
      iconUrl: json['icon_url'] as String?,
      color: json['color'] as String,
      isActive: json['is_active'] as bool,
      subcategoriesCount: (json['subcategories_count'] as num?)?.toInt(),
      subcategories:
          (json['subcategories'] as List<dynamic>?)
              ?.map(
                (e) => SubcategoryResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CategoryResponseToJson(_CategoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'icon_url': instance.iconUrl,
      'color': instance.color,
      'is_active': instance.isActive,
      'subcategories_count': instance.subcategoriesCount,
      'subcategories': instance.subcategories,
    };
