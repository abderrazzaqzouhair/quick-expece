import '../../domain/entities/category_entity.dart';
import '../../domain/entities/subcategory_entity.dart';
import '../models/category_response.dart';
import '../models/subcategory_response.dart';

/// DTO -> domain entity mapping. Keep all shape-translation here so
/// `RepositoryImpl` stays focused on orchestration.
extension CategoryResponseMapper on CategoryResponse {
  CategoryEntity toEntity() => CategoryEntity(
    id: id,
    name: name,
    color: color,
    isActive: isActive,
    icon: icon,
    iconUrl: iconUrl,
    subcategoriesCount: subcategoriesCount,
    subcategories: subcategories.map((s) => s.toEntity()).toList(),
  );
}

extension SubcategoryResponseMapper on SubcategoryResponse {
  SubcategoryEntity toEntity() => SubcategoryEntity(
    id: id,
    categoryId: categoryId,
    name: name,
    isActive: isActive,
    icon: icon,
    iconUrl: iconUrl,
  );
}
