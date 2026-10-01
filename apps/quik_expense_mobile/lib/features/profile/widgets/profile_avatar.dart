import 'package:flutter/material.dart';

import '../data/profile_store.dart';

/// Circular initials avatar on a soft gradient of the chosen colour; a
/// person glyph when there's no name yet.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 64});

  final UserProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = profile.color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: profile.hasName
          ? Text(
              profile.initials,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            )
          : Icon(Icons.person_rounded, size: size * 0.5, color: Colors.white),
    );
  }
}
