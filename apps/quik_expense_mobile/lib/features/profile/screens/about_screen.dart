import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_info.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/settings_list.dart';

/// App identity, version, source code and open-source licenses.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openSource(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(AppInfo.sourceCodeUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        appToast('Couldn\'t open the browser.', kind: ToastKind.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'About',
      children: [
        const SizedBox(height: 12),
        const Center(child: AppLogo(size: 88)),
        const SizedBox(height: 16),
        const Text(
          AppInfo.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          AppInfo.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        SettingsGroup(
          children: [
            const SettingsTile(
              icon: Icons.verified_rounded,
              iconColor: Color(0xFF34C759),
              title: 'Version',
              value: AppInfo.version,
            ),
            const SettingsTile(
              icon: Icons.flutter_dash_rounded,
              iconColor: Color(0xFF02569B),
              title: 'Built with Flutter',
              value: 'Offline-first',
            ),
            SettingsTile(
              icon: Icons.code_rounded,
              iconColor: const Color(0xFF1B1B1B),
              title: 'Source code',
              subtitle: 'github.com/abderrazzaqzouhair/quick-expece',
              onTap: () => _openSource(context),
            ),
            SettingsTile(
              icon: Icons.description_rounded,
              iconColor: const Color(0xFF8E8E93),
              title: 'Open-source licenses',
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppInfo.name,
                applicationVersion: AppInfo.version,
                applicationIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: AppLogo(size: 56),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
