import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cse_b2b/core/theme/app_radii.dart';

/// The 6-digit OTP entry used by every login-context OTP screen (A2, A3,
/// B2) — six boxed digits (Claude Design's `Input`-adjacent OTP treatment:
/// 58px boxes, 12px radius, mono digits), backed by one real [TextField]
/// so the platform numeric keyboard and paste/autofill behave normally,
/// with the boxes drawn from its current text rather than six separate
/// focus nodes.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final defaultBorder = theme.colorScheme.outline;
    final focusBorder = theme.colorScheme.primary;

    return GestureDetector(
      onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final digits = widget.controller.text;
              final hasFocus = _focusNode.hasFocus;
              return Row(
                children: List.generate(widget.length, (i) {
                  final filled = i < digits.length;
                  final isCursor = i == digits.length && hasFocus;
                  final border = widget.hasError
                      ? errorColor
                      : isCursor
                      ? focusBorder
                      : defaultBorder;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: i == widget.length - 1 ? 0 : 9,
                      ),
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: AppRadii.mdRadius,
                        border: Border.all(
                          color: border,
                          width: widget.hasError ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        filled ? digits[i] : '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: widget.hasError
                              ? errorColor
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              onChanged: widget.onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
