import 'package:flutter/material.dart';

/// Parses the `#RRGGBB` / `#AARRGGBB` hex strings the backend stores for
/// category colors (see `CategorySeeder`) into a [Color].
abstract final class HexColor {
  static Color fromHex(String hexString) {
    var hex = hexString.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
