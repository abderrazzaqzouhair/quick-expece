import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/haptics.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../../shared/widgets/settings_list.dart';
import '../data/profile_providers.dart';
import '../data/profile_store.dart';

/// Preferences and data management: haptics, CSV export, reset category
/// choices, delete all expenses.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final (csv, count) = await ref.read(dataActionsProvider).exportCsv();
    if (count == 0) {
      messenger.showSnackBar(appToast('No expenses to export yet.'));
      return;
    }
    await Clipboard.setData(ClipboardData(text: csv));
    Haptics.medium();
    messenger.showSnackBar(
      appToast(
        '$count ${count == 1 ? 'expense' : 'expenses'} copied as CSV — '
        'paste into Sheets or Excel',
        kind: ToastKind.success,
      ),
    );
  }

  Future<void> _deleteAll(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    if (count == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(appToast('There are no expenses to delete.'));
      return;
    }
    final confirmed = await confirmDestructive(
      context,
      icon: Icons.delete_forever_rounded,
      title: 'Delete all $count expenses?',
      message:
          'This clears your whole history, totals and statistics. '
          'Tip: export them as CSV first.',
      confirmLabel: 'Delete All Expenses',
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await ref.read(dataActionsProvider).deleteAllExpenses();
    Haptics.medium();
    messenger.showSnackBar(
      appToast('$deleted expenses deleted', kind: ToastKind.success),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final count = ref.watch(expenseSummaryProvider).value?.count ?? 0;

    return SettingsScaffold(
      title: 'Settings',
      children: [
        SettingsGroup(
          title: 'Preferences',
          children: [
            SettingsTile(
              icon: Icons.vibration_rounded,
              iconColor: const Color(0xFFFF2D55),
              title: 'Haptic feedback',
              subtitle: 'Subtle taps on keys, saves and swipes',
              trailing: SettingsSwitch(
                value: settings.hapticsEnabled,
                onChanged: ref.read(settingsProvider.notifier).setHaptics,
              ),
            ),
            const SettingsTile(
              icon: Icons.payments_rounded,
              iconColor: Color(0xFF34C759),
              title: 'Currency',
              value: 'MAD',
            ),
          ],
        ),
        SettingsGroup(
          title: 'Your data',
          footer:
              'The CSV is copied to your clipboard — paste it into '
              'Google Sheets, Excel or a note to keep a backup.',
          children: [
            SettingsTile(
              icon: Icons.ios_share_rounded,
              iconColor: const Color(0xFF007AFF),
              title: 'Export expenses (CSV)',
              value: '$count',
              onTap: () => _export(context, ref),
            ),
            SettingsTile(
              icon: Icons.restart_alt_rounded,
              iconColor: const Color(0xFFFF9500),
              title: 'Show all categories',
              subtitle: 'Undo every hidden category and subcategory',
              showChevron: false,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(dataActionsProvider).showAllCategories();
                Haptics.medium();
                messenger.showSnackBar(
                  appToast(
                    'All categories are visible',
                    kind: ToastKind.success,
                  ),
                );
              },
            ),
          ],
        ),
        SettingsGroup(
          title: 'Danger zone',
          children: [
            SettingsTile(
              icon: Icons.delete_forever_rounded,
              iconColor: SettingsTile.destructiveColor,
              title: 'Delete all expenses',
              destructive: true,
              showChevron: false,
              onTap: () => _deleteAll(context, ref, count),
            ),
          ],
        ),
      ],
    );
  }
}
