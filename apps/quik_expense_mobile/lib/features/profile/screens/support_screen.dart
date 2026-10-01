import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_info.dart';
import '../../../shared/haptics.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/settings_list.dart';

/// Help & contact: email support, report a bug (pre-filled with app/device
/// info), copy the address, and an FAQ.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faq = [
    (
      'Where is my data stored?',
      'Only on this phone, in a private database. Nothing is uploaded — '
          'there is no account or server.',
    ),
    (
      'How do I back up my expenses?',
      'Profile → Settings → Export expenses (CSV) copies everything to your '
          'clipboard. Paste it into Google Sheets, Excel or a note.',
    ),
    (
      'Can I undo a delete?',
      'Yes — after swiping an expense away in History, tap Undo on the '
          'message at the bottom of the screen.',
    ),
    (
      'How do I hide categories I never use?',
      'Profile → Categories. Turn off a category, or open it to choose '
          'which subcategories appear when you add an expense.',
    ),
    (
      'Why is a day or week missing in Statistics?',
      'Statistics only counts days that have started — future days show as '
          'faint bars and never lower your average.',
    ),
  ];

  static Future<void> _email(
    BuildContext context, {
    required String subject,
    String body = '',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfo.supportEmail,
      query: _encodeQuery({'subject': subject, 'body': body}),
    );
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: AppInfo.supportEmail));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(appToast('No email app found — address copied instead.'));
    }
  }

  /// mailto needs %20 for spaces (Uri's queryParameters would use '+').
  static String _encodeQuery(Map<String, String> params) => params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');

  static String get _deviceInfo =>
      '\n\n---\n${AppInfo.name} ${AppInfo.version}\n'
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Help & Contact',
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: Colors.white, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We\'re here to help',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Questions, ideas or bugs — every message is read.',
                      style: TextStyle(fontSize: 13.5, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Contact',
          children: [
            SettingsTile(
              icon: Icons.mail_rounded,
              iconColor: const Color(0xFF007AFF),
              title: 'Email us',
              subtitle: AppInfo.supportEmail,
              onTap: () =>
                  _email(context, subject: '${AppInfo.name} — question'),
            ),
            SettingsTile(
              icon: Icons.bug_report_rounded,
              iconColor: const Color(0xFFFF3B30),
              title: 'Report a bug',
              subtitle: 'Opens an email with your app version',
              onTap: () => _email(
                context,
                subject: '${AppInfo.name} — bug report',
                body:
                    'What happened?\n\n\nWhat did you expect?\n'
                    '$_deviceInfo',
              ),
            ),
            SettingsTile(
              icon: Icons.lightbulb_rounded,
              iconColor: const Color(0xFFFFCC00),
              title: 'Suggest a feature',
              onTap: () =>
                  _email(context, subject: '${AppInfo.name} — feature idea'),
            ),
            SettingsTile(
              icon: Icons.copy_rounded,
              iconColor: const Color(0xFF8E8E93),
              title: 'Copy email address',
              showChevron: false,
              onTap: () async {
                await Clipboard.setData(
                  const ClipboardData(text: AppInfo.supportEmail),
                );
                Haptics.light();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    appToast('Email copied', kind: ToastKind.success),
                  );
                }
              },
            ),
          ],
        ),
        SettingsGroup(
          title: 'Frequently asked',
          children: [
            for (final (question, answer) in _faq)
              _FaqTile(question: question, answer: answer),
          ],
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // No divider lines from ExpansionTile — the group draws its own.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.centerLeft,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        onExpansionChanged: (_) => Haptics.selection(),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
