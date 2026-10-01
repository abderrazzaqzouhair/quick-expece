import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/haptics.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../../shared/widgets/settings_list.dart';
import '../data/profile_providers.dart';

/// What the app stores, where, and the promises it keeps — plus "erase
/// everything" to return to a fresh install.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  static const _promises = [
    (
      Icons.phone_iphone_rounded,
      Color(0xFF007AFF),
      'Stored on this phone',
      'Expenses live in a private on-device database. No cloud copy.',
    ),
    (
      Icons.person_off_rounded,
      Color(0xFF5856D6),
      'No account required',
      'Your name and email are optional and never leave the device.',
    ),
    (
      Icons.visibility_off_rounded,
      Color(0xFF34C759),
      'No tracking or analytics',
      'The app doesn\'t collect usage data or send anything to servers.',
    ),
    (
      Icons.block_rounded,
      Color(0xFFFF9500),
      'No ads',
      'Nothing is shown to you for money, and nothing is sold.',
    ),
  ];

  Future<void> _erase(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructive(
      context,
      icon: Icons.warning_rounded,
      title: 'Erase all data?',
      message:
          'Deletes every expense, resets your profile, settings and '
          'category choices. This is like reinstalling the app.',
      confirmLabel: 'Erase Everything',
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(dataActionsProvider).eraseEverything();
    Haptics.medium();
    messenger.showSnackBar(
      appToast('All data erased', kind: ToastKind.success),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsScaffold(
      title: 'Privacy & Security',
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6D6AF0), Color(0xFF4338CA)],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Your money, your business',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Everything you record stays on this phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Our promises',
          children: [
            for (final (icon, color, title, subtitle) in _promises)
              SettingsTile(
                icon: icon,
                iconColor: color,
                title: title,
                subtitle: subtitle,
              ),
          ],
        ),
        const SettingsGroup(
          title: 'What\'s stored',
          footer:
              'Removing the app from your phone deletes all of this. Export '
              'a CSV from Settings first if you want a copy.',
          children: [
            SettingsTile(
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.primary,
              title: 'Expenses',
              subtitle: 'Amount, date, category and your note',
            ),
            SettingsTile(
              icon: Icons.person_rounded,
              iconColor: Color(0xFF3B82F6),
              title: 'Profile',
              subtitle: 'Name, email and avatar colour (optional)',
            ),
            SettingsTile(
              icon: Icons.tune_rounded,
              iconColor: Color(0xFF8E8E93),
              title: 'Preferences',
              subtitle: 'Haptics and which categories you show',
            ),
          ],
        ),
        SettingsGroup(
          title: 'Danger zone',
          children: [
            SettingsTile(
              icon: Icons.delete_forever_rounded,
              iconColor: SettingsTile.destructiveColor,
              title: 'Erase all data',
              destructive: true,
              showChevron: false,
              onTap: () => _erase(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}
