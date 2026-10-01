import 'package:equatable/equatable.dart';

import 'subcategory_entity.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.color,
    required this.isActive,
    this.icon,
    this.iconUrl,
    this.subcategoriesCount,
    this.subcategories = const [],
  });

  final int id;
  final String name;

  /// Hex color from the backend, e.g. `#F59E0B` — parse with `HexColor` from
  /// `ui_kit`.
  final String color;
  final bool isActive;

  /// Relative path under the backend's `public/` dir, e.g.
  /// `icons/categories/food-drinks.svg`.
  final String? icon;

  /// Absolute URL to [icon] — render this directly (see `AppRemoteIcon` in
  /// `ui_kit`).
  final String? iconUrl;

  /// Only present when the list endpoint eager-loads the count.
  final int? subcategoriesCount;

  /// Only populated when the list endpoint eager-loads the relation.
  final List<SubcategoryEntity> subcategories;

  @override
  List<Object?> get props => [
    id,
    name,
    color,
    isActive,
    icon,
    iconUrl,
    subcategoriesCount,
    subcategories,
  ];
}
