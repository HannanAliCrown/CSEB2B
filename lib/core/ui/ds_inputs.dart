import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// The design system's `Input`: 14/500 label, a 52px field with a hairline
/// border (accent + focus ring when focused, error red when invalid), and a
/// caption row for the hint/error and an optional right-aligned range.
class DsInput extends StatelessWidget {
  const DsInput({
    super.key,
    this.label,
    this.value,
    this.placeholder,
    this.hint,
    this.error,
    this.unit,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.focused = false,
    this.keyboardType,
    this.controller,
    this.onChanged,
    this.obscure = false,
    this.maxLines = 1,
    this.trailingCaption,
    this.inputFormatters,
  });

  final String? label;
  final String? value;
  final String? placeholder;
  final String? hint;
  final String? error;
  final String? unit;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final bool readOnly;

  /// Renders the focus ring without requiring real keyboard focus — the
  /// design shows focused fields in several static states.
  final bool focused;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final int maxLines;
  final String? trailingCaption;

  /// Constrains what can be typed, e.g. digits only up to a fixed length.
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final borderColor = hasError
        ? context.colors.error
        : focused
        ? context.colors.primary
        : context.colors.outline;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Container(
            constraints: BoxConstraints(
              minHeight: maxLines > 1 ? 96 : AppSpacing.inputHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: readOnly ? Colors.transparent : context.colors.surface,
              borderRadius: AppRadii.mdRadius,
              border: Border.all(color: borderColor),
              boxShadow: focused && !hasError
                  ? [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.32),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: maxLines > 1
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (prefix != null) ...[prefix!, const SizedBox(width: 10)],
                Expanded(
                  child: TextField(
                    controller:
                        controller ??
                        (value == null
                            ? null
                            : TextEditingController(text: value)),
                    enabled: enabled && !readOnly,
                    obscureText: obscure,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    maxLines: maxLines,
                    minLines: maxLines > 1 ? maxLines : 1,
                    onChanged: onChanged,
                    style: context.texts.bodyLarge,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: maxLines > 1 ? AppSpacing.stepMd : 0,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: placeholder,
                      hintStyle: context.texts.bodyLarge?.copyWith(
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ),
                ),
                if (unit != null)
                  Text(
                    unit!,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.palette.textTertiary,
                    ),
                  ),
                if (suffix != null) ...[const SizedBox(width: 10), suffix!],
              ],
            ),
          ),
          if (error != null || hint != null || trailingCaption != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      error ?? hint ?? '',
                      style: context.texts.bodySmall?.copyWith(
                        color: hasError
                            ? context.colors.error
                            : context.palette.textTertiary,
                      ),
                    ),
                  ),
                  if (trailingCaption != null)
                    Text(
                      trailingCaption!,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.palette.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The design system's `Select`: same shell as [DsInput] with a chevron and a
/// placeholder-coloured value when empty.
class DsSelect extends StatelessWidget {
  const DsSelect({
    super.key,
    this.label,
    this.value,
    this.placeholder = 'Select',
    this.enabled = true,
    this.error,
    this.hint,
    this.onTap,
  });

  final String? label;
  final String? value;
  final String placeholder;
  final bool enabled;
  final String? error;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppRadii.mdRadius,
            child: Container(
              height: AppSpacing.inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: AppRadii.mdRadius,
                border: Border.all(
                  color: error != null
                      ? context.colors.error
                      : context.colors.outline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? value! : placeholder,
                      style: context.texts.bodyLarge?.copyWith(
                        color: hasValue ? null : context.palette.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: context.palette.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (error != null || hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                error ?? hint!,
                style: context.texts.bodySmall?.copyWith(
                  color: error != null
                      ? context.colors.error
                      : context.palette.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The design system's `Checkbox`: 22px box, 6px corners, accent fill when
/// checked, 48px minimum row height.
class DsCheckbox extends StatelessWidget {
  const DsCheckbox({
    super.key,
    required this.checked,
    required this.label,
    this.description,
    this.enabled = true,
    this.onChanged,
  });

  final bool checked;
  final String label;
  final String? description;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled && onChanged != null ? () => onChanged!(!checked) : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.tapMin),
          child: Row(
            crossAxisAlignment: description != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: EdgeInsets.only(top: description != null ? 2 : 0),
                decoration: BoxDecoration(
                  color: checked ? context.colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: checked
                        ? context.colors.primary
                        : context.palette.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: checked
                    ? const Icon(
                        LucideIcons.check,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: context.texts.bodyLarge),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          description!,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.palette.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The design system's `Radio`: a 22px ring with an accent dot when selected.
class DsRadio extends StatelessWidget {
  const DsRadio({
    super.key,
    required this.selected,
    required this.label,
    this.description,
    this.trailing,
    this.enabled = true,
    this.onTap,
  });

  final bool selected;
  final String label;
  final String? description;
  final Widget? trailing;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.tapMin),
          child: Row(
            crossAxisAlignment: description != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: EdgeInsets.only(top: description != null ? 2 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? context.colors.primary
                        : context.palette.borderStrong,
                    width: selected ? 6 : 1.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: context.texts.bodyLarge),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          description!,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.palette.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// The design system's `Switch`: a 48x28 track with a 22px knob.
class DsSwitch extends StatelessWidget {
  const DsSwitch({
    super.key,
    required this.checked,
    this.onChanged,
    this.enabled = true,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled && onChanged != null ? () => onChanged!(!checked) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: checked
                ? context.colors.primary
                : context.palette.borderStrong,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The OTP entry row the login and registration flows share: equal-width
/// 58px boxes, 22/600 monospace digits, error-tinted when invalid.
class DsOtpBoxes extends StatelessWidget {
  const DsOtpBoxes({
    super.key,
    required this.digits,
    this.length = 6,
    this.error = false,
    this.focusedIndex,
  });

  final String digits;
  final int length;
  final bool error;
  final int? focusedIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(length, (i) {
        final filled = i < digits.length;
        final borderColor = error
            ? context.colors.error
            : i == focusedIndex
            ? context.colors.primary
            : context.colors.outline;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == length - 1 ? 0 : 9),
            child: Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: AppRadii.mdRadius,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Text(
                filled ? digits[i] : '',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: error
                      ? context.status.error
                      : context.colors.onSurface,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// The resend row under an OTP entry: a countdown on the left and the resend
/// action on the right, greyed until the countdown reaches zero.
class DsResendRow extends StatelessWidget {
  const DsResendRow({super.key, required this.countdown, this.onResend});

  final String countdown;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final enabled = onResend != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text.rich(
            overflow: TextOverflow.ellipsis,
            TextSpan(
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              children: [
                const TextSpan(text: 'Resend code in '),
                TextSpan(
                  text: countdown,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.stepMd),
        GestureDetector(
          onTap: onResend,
          child: Text(
            'Resend',
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled
                  ? context.colors.primary
                  : context.palette.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The 4-digit PIN dots used by App Security (board 02 C1, board 11).
class DsPinDots extends StatelessWidget {
  const DsPinDots({
    super.key,
    required this.filled,
    this.length = 4,
    this.error = false,
  });

  final int filled;
  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final on = i < filled;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on
                ? (error ? context.colors.error : context.colors.primary)
                : Colors.transparent,
            border: Border.all(
              color: error
                  ? context.colors.error
                  : context.palette.borderStrong,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

/// The numeric keypad the PIN screens use: a 3-column grid of 64px surface
/// cards with 24/600 digits, a blank cell and a backspace key.
class DsKeypad extends StatelessWidget {
  const DsKeypad({super.key, this.onDigit, this.onBackspace});

  final ValueChanged<String>? onDigit;
  final VoidCallback? onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];
    // Always left to right, whatever the app's language is. A numeric keypad
    // reads the same way everywhere — the phone's own dialler does not
    // mirror in Urdu either, and a mirrored one puts 1 where 3 should be.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Padding(
              padding: EdgeInsets.only(bottom: row == 3 ? 0 : 14),
              child: Row(
                children: [
                  for (var col = 0; col < 3; col++) ...[
                    Expanded(child: _key(context, keys[row * 3 + col])),
                    if (col != 2) const SizedBox(width: 14),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, String key) {
    if (key.isEmpty) return const SizedBox(height: 64);
    final content = key == 'back'
        ? Icon(
            LucideIcons.delete,
            size: 24,
            color: context.colors.onSurfaceVariant,
          )
        : Text(
            key,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          );
    return InkWell(
      onTap: key == 'back' ? onBackspace : () => onDigit?.call(key),
      borderRadius: AppRadii.lgRadius,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadii.lgRadius,
          border: Border.all(color: context.colors.outline),
        ),
        child: content,
      ),
    );
  }
}
