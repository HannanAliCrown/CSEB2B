import 'package:flutter/material.dart';

/// The primary call-to-action button repeated across the Login journey
/// ("Sign In", "Verify and Sign In", "Continue and Verify") — a themed
/// [ElevatedButton] (colour/height/radius come entirely from
/// `AppTheme.elevatedButtonTheme`) that additionally swaps its label for a
/// spinner while [loading], matching the design system's `Button` loading
/// state (`loading && <Spinner/>` replacing the children).
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
