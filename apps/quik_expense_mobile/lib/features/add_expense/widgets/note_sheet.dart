import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/widgets/app_sheet.dart';

/// Max note length — the database column limit.
const maxNoteLength = 1000;

/// Multi-line note editor in a sheet that rides above the keyboard.
/// Returns the edited text (possibly empty), or `null` if cancelled.
Future<String?> showNoteSheet(BuildContext context, String initial) {
  return showAppSheet<String>(
    context,
    builder: (_) => _NoteSheet(initial: initial),
  );
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.initial});

  final String initial;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(
            title: 'Note',
            leading: SheetTextButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            trailing: SheetTextButton(
              label: 'Done',
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(_controller.text),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: maxNoteLength,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: AppColors.primary,
              style: const TextStyle(
                fontSize: 17,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. Lunch with Sara',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                counterStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
