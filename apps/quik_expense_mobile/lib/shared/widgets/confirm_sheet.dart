import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import 'app_sheet.dart';
import 'pressable.dart';

/// iOS action-sheet style confirmation for destructive actions. Returns
/// `true` only when the user taps the confirm button.
Future<bool> confirmDestructive(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF3B30), size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _SheetButton(
            label: confirmLabel,
            color: const Color(0xFFFF3B30),
            textColor: Colors.white,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          _SheetButton(
            label: 'Cancel',
            color: AppColors.surface,
            textColor: AppColors.textPrimary,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      semanticLabel: label,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
