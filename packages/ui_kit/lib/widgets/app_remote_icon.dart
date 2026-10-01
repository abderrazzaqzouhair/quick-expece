import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a category/subcategory icon from the backend's `icon_url` (an
/// absolute URL to an SVG under Laravel's `public/icons/...`). Falls back to
/// [fallbackIcon] when the URL is null or fails to load.
class AppRemoteIcon extends StatelessWidget {
  const AppRemoteIcon({
    super.key,
    required this.iconUrl,
    this.size = 24,
    this.color,
    this.fallbackIcon = Icons.category_outlined,
  });

  final String? iconUrl;
  final double size;
  final Color? color;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final url = iconUrl;
    if (url == null || url.isEmpty) {
      return Icon(fallbackIcon, size: size, color: color);
    }
    return SvgPicture.network(
      url,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      placeholderBuilder: (context) => SizedBox.square(
        dimension: size,
        child: const CircularProgressIndicator(strokeWidth: 1.5),
      ),
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, size: size, color: color),
    );
  }
}
