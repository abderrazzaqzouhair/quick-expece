import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../config/providers/preferences_providers.dart';
import '../../../shared/haptics.dart';

/// Avatar background choices (index stored in preferences).
const avatarColors = <Color>[
  AppColors.primary,
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF0EA5E9),
  Color(0xFF64748B),
];

@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.colorIndex,
    required this.memberSince,
  });

  final String name;
  final String email;
  final int colorIndex;

  /// When the app was first opened on this device.
  final DateTime memberSince;

  bool get hasName => name.trim().isNotEmpty;

  Color get color => avatarColors[colorIndex % avatarColors.length];

  /// Up to two initials ("Sara Ali" → "SA"); "?" without a name.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// The user's local profile (no account/server — stays on the device).
final profileProvider = NotifierProvider<ProfileController, UserProfile>(
  ProfileController.new,
);

class ProfileController extends Notifier<UserProfile> {
  static const _name = 'profile.name';
  static const _email = 'profile.email';
  static const _color = 'profile.colorIndex';
  static const _since = 'profile.memberSince';

  @override
  UserProfile build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    var since = DateTime.tryParse(prefs.getString(_since) ?? '');
    if (since == null) {
      since = DateTime.now();
      prefs.setString(_since, since.toIso8601String());
    }
    return UserProfile(
      name: prefs.getString(_name) ?? '',
      email: prefs.getString(_email) ?? '',
      colorIndex: prefs.getInt(_color) ?? 0,
      memberSince: since,
    );
  }

  Future<void> save({
    required String name,
    required String email,
    required int colorIndex,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_name, name.trim());
    await prefs.setString(_email, email.trim());
    await prefs.setInt(_color, colorIndex);
    state = UserProfile(
      name: name.trim(),
      email: email.trim(),
      colorIndex: colorIndex,
      memberSince: state.memberSince,
    );
  }

  /// Clears name/email/colour (keeps "member since").
  Future<void> reset() => save(name: '', email: '', colorIndex: 0);
}

@immutable
class AppSettings {
  const AppSettings({required this.hapticsEnabled});

  final bool hapticsEnabled;
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _haptics = 'settings.haptics';

  @override
  AppSettings build() {
    final enabled =
        ref.watch(sharedPreferencesProvider).getBool(_haptics) ?? true;
    Haptics.enabled = enabled;
    return AppSettings(hapticsEnabled: enabled);
  }

  Future<void> setHaptics(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_haptics, enabled);
    Haptics.enabled = enabled;
    state = AppSettings(hapticsEnabled: enabled);
    Haptics.selection(); // confirms "on" with a tap
  }

  Future<void> reset() => setHaptics(true);
}
