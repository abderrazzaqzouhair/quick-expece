import 'package:equatable/equatable.dart';

class SubcategoryEntity extends Equatable {
  const SubcategoryEntity({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.isActive,
    this.icon,
    this.iconUrl,
  });

  final int id;
  final int categoryId;
  final String name;
  final bool isActive;

  /// Relative path under the backend's `public/` dir, e.g.
  /// `icons/subcategories/food-drinks/groceries.svg`.
  final String? icon;

  /// Absolute URL to [icon] — render this directly (see `AppRemoteIcon` in
  /// `ui_kit`).
  final String? iconUrl;

  @override
  List<Object?> get props => [id, categoryId, name, isActive, icon, iconUrl];
}
