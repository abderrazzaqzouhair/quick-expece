import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/haptics.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/profile_store.dart';
import '../widgets/profile_avatar.dart';

/// Name, email and avatar colour — saved locally. Save is enabled only for
/// valid changes; leaving with unsaved edits asks to discard them.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const maxNameLength = 40;

  final _formKey = GlobalKey<FormState>();
  late final UserProfile _initial;
  late final TextEditingController _name;
  late final TextEditingController _email;
  late int _colorIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initial = ref.read(profileProvider);
    _name = TextEditingController(text: _initial.name)..addListener(_onChanged);
    _email = TextEditingController(text: _initial.email)
      ..addListener(_onChanged);
    _colorIndex = _initial.colorIndex;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isDirty =>
      _name.text.trim() != _initial.name ||
      _email.text.trim() != _initial.email ||
      _colorIndex != _initial.colorIndex;

  /// Live preview of the avatar as the user types / picks.
  UserProfile get _preview => UserProfile(
    name: _name.text,
    email: _email.text,
    colorIndex: _colorIndex,
    memberSince: _initial.memberSince,
  );

  static String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your name.';
    if (name.length > maxNameLength) {
      return 'Keep it under $maxNameLength characters.';
    }
    return null;
  }

  static String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null; // optional
    return _emailPattern.hasMatch(email) ? null : 'Enter a valid email.';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      Haptics.heavy();
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(profileProvider.notifier)
        .save(name: _name.text, email: _email.text, colorIndex: _colorIndex);
    if (!mounted) return;
    Haptics.medium();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(appToast('Profile saved', kind: ToastKind.success));
    context.pop();
  }

  Future<void> _confirmDiscard() async {
    final discard = await confirmDestructive(
      context,
      icon: Icons.edit_off_rounded,
      title: 'Discard changes?',
      message: 'Your edits to the profile haven\'t been saved.',
      confirmLabel: 'Discard',
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _isDirty && !_saving;

    return PopScope(
      canPop: !_isDirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            TextButton(
              onPressed: canSave ? _save : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(64, 44),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Center(child: ProfileAvatar(profile: _preview, size: 104)),
              const SizedBox(height: 20),
              _ColorPicker(
                selected: _colorIndex,
                onSelected: (i) {
                  Haptics.selection();
                  setState(() => _colorIndex = i);
                },
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Name',
                hintText: 'e.g. Sara Alaoui',
                prefixIcon: Icons.person_rounded,
                controller: _name,
                validator: _validateName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Email (optional)',
                hintText: 'you@example.com',
                prefixIcon: Icons.mail_rounded,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) {
                  if (canSave) _save();
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Your profile is stored only on this phone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const _names = [
    'Orange',
    'Blue',
    'Green',
    'Purple',
    'Pink',
    'Sky',
    'Slate',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < avatarColors.length; i++)
          Pressable(
            onTap: () => onSelected(i),
            semanticLabel:
                '${_names[i]} avatar colour${i == selected ? ', selected' : ''}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: i == selected ? avatarColors[i] : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: avatarColors[i],
                  shape: BoxShape.circle,
                ),
                child: i == selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
