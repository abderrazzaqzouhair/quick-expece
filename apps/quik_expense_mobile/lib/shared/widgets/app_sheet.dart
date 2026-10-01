import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Presents an iOS-style bottom sheet: grabber, large top radius, grouped
/// light-grey background, safe-area aware. Returns whatever the sheet pops.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: builder,
  );
}

/// Sheet header: grabber, centered title, optional leading/trailing actions
/// (iOS nav-bar layout inside a sheet).
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (leading != null)
                Positioned(left: 4, top: 0, bottom: 0, child: leading!),
              if (trailing != null)
                Positioned(right: 4, top: 0, bottom: 0, child: trailing!),
            ],
          ),
        ),
      ],
    );
  }
}

/// Text action for a sheet header ("Done", "Cancel") — iOS style, bold when
/// it's the confirming action.
class SheetTextButton extends StatelessWidget {
  const SheetTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 17,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// White rounded container for an iOS "inset grouped" list.
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 16,
                color: AppColors.border,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
