import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

enum ToastKind { success, error, info }

/// Dark floating toast, lifted above the bottom nav. Optional action (e.g.
/// Undo).
SnackBar appToast(
  String text, {
  ToastKind kind = ToastKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final (icon, color) = switch (kind) {
    ToastKind.success => (Icons.check_circle_rounded, const Color(0xFF34C759)),
    ToastKind.error => (Icons.error_rounded, AppColors.error),
    ToastKind.info => (Icons.info_rounded, Colors.white70),
  };

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.textPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
    duration: Duration(seconds: actionLabel == null ? 3 : 5),
    action: actionLabel == null
        ? null
        : SnackBarAction(
            label: actionLabel,
            textColor: AppColors.primaryLight,
            onPressed: onAction ?? () {},
          ),
    content: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}
