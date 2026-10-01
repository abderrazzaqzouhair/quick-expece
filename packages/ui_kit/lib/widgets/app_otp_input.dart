import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A row of [length] digit boxes backed by a single invisible [TextField] —
/// avoids juggling one `FocusNode` per box (fragile: backspace-to-previous-box
/// needs raw key interception across multiple focus nodes). One real text
/// field means backspace, paste, and autofill all just work; the boxes are
/// purely decorative, driven by the field's current text.
class AppOtpInput extends StatefulWidget {
  const AppOtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.autofocus = true,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<AppOtpInput> createState() => _AppOtpInputState();
}

class _AppOtpInputState extends State<AppOtpInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  void _handleChanged(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, _buildBox),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                autocorrect: false,
                enableSuggestions: false,
                showCursor: false,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: _handleChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBox(int index) {
    final text = _controller.text;
    final digit = index < text.length ? text[index] : '';
    final isCurrent = _focusNode.hasFocus && index == text.length;

    return Container(
      width: 46,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 1.6 : 1,
        ),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
