import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/ds.dart';

/// Makes the design's OTP boxes typeable without changing how they look.
///
/// The boxes themselves are still [DsOtpBoxes]; a transparent field sits on
/// top to collect the digits and drive them. Tapping anywhere on the row
/// opens the keyboard, exactly as the design implies.
class EditableOtpField extends StatefulWidget {
  const EditableOtpField({
    super.key,
    required this.controller,
    this.length = 6,
    this.error = false,
    this.onCompleted,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final int length;
  final bool error;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<EditableOtpField> createState() => _EditableOtpFieldState();
}

class _EditableOtpFieldState extends State<EditableOtpField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          DsOtpBoxes(
            digits: digits,
            length: widget.length,
            error: widget.error,
            focusedIndex: digits.length < widget.length ? digits.length : null,
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
