import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// UI-only icon + colour for a category. Icons aren't stored in the database
/// (by design) — they're mapped from the catalogue name here, with a
/// neutral fallback for anything unknown.
abstract final class CategoryVisuals {
  static const _icons = <String, IconData>{
    'Food & Drinks': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Housing & Living': Icons.home_rounded,
    'Entertainment & Fun': Icons.sports_esports_rounded,
    'Personal & Lifestyle': Icons.checkroom_rounded,
    'Subscriptions & Digital': Icons.subscriptions_rounded,
    'Education & Learning': Icons.school_rounded,
    'Health & Medical': Icons.medical_services_rounded,
    'Social & Gifts': Icons.card_giftcard_rounded,
    'Travel': Icons.flight_rounded,
    'Bills & Financial': Icons.receipt_long_rounded,
    'Miscellaneous': Icons.category_rounded,
  };

  static IconData iconFor(String categoryName) =>
      _icons[categoryName] ?? Icons.label_rounded;

  static Color colorFor(String? hex) =>
      hex == null ? AppColors.primary : HexColor.fromHex(hex);
}

/// Rounded-square tile with the category icon on a soft tint of its colour
/// — the iOS "app icon" treatment used in pickers and lists.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.name,
    required this.colorHex,
    this.size = 44,
  });

  final String name;
  final String? colorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.colorFor(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        CategoryVisuals.iconFor(name),
        size: size * 0.5,
        color: color,
      ),
    );
  }
}
