import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// The dark camera surface every scanning screen shares: a title row, the
/// gold-cornered viewfinder with its scan line, and a footer area.
class ScannerScaffold extends StatelessWidget {
  const ScannerScaffold({
    super.key,
    required this.title,
    required this.hint,
    this.tabs,
    this.footer,
    this.trailingIcon = LucideIcons.circleHelp,
  });

  final String title;
  final String hint;

  /// The Scan to Earn / Authenticity Check switch, where the role has both.
  final Widget? tabs;
  final Widget? footer;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                6,
                AppSpacing.screenPadding,
                14,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Icon(trailingIcon, size: 22, color: Colors.white),
                ],
              ),
            ),
            if (tabs != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: tabs!,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ViewfinderFrame(gold: context.palette.crownGold),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, AppSpacing.md, 24, 30),
              child: footer ?? const TorchControl(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The viewfinder: a translucent square with gold corner brackets and a
/// scan line across the middle.
class ViewfinderFrame extends StatelessWidget {
  const ViewfinderFrame({super.key, required this.gold});

  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadii.sheet),
          ),
        ),
        _corner(top: true, left: true),
        _corner(top: true, left: false),
        _corner(top: false, left: true),
        _corner(top: false, left: false),
        Positioned(
          left: 8,
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(height: 2, color: gold.withValues(alpha: 0.85)),
          ),
        ),
      ],
    );
  }

  Widget _corner({required bool top, required bool left}) {
    const radius = Radius.circular(AppRadii.sheet);
    return Positioned(
      top: top ? -2 : null,
      bottom: top ? null : -2,
      left: left ? -2 : null,
      right: left ? null : -2,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: top && left ? radius : Radius.zero,
            topRight: top && !left ? radius : Radius.zero,
            bottomLeft: !top && left ? radius : Radius.zero,
            bottomRight: !top && !left ? radius : Radius.zero,
          ),
          border: Border(
            top: top ? BorderSide(color: gold, width: 4) : BorderSide.none,
            bottom: top ? BorderSide.none : BorderSide(color: gold, width: 4),
            left: left ? BorderSide(color: gold, width: 4) : BorderSide.none,
            right: left ? BorderSide.none : BorderSide(color: gold, width: 4),
          ),
        ),
      ),
    );
  }
}

/// The torch toggle under the viewfinder.
class TorchControl extends StatelessWidget {
  const TorchControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.flashlight,
          size: 20,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Torch',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// The pill switch between the two scanning capabilities, drawn for the dark
/// camera surface.
class ScannerTabs extends StatelessWidget {
  const ScannerTabs({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    option,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: option == value
                          ? const Color(0xFF0B0F14)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A translucent note on the camera surface — the daily scan counter and
/// similar footnotes.
class ScannerNote extends StatelessWidget {
  const ScannerNote({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadii.mdRadius,
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          height: 17 / 12,
          color: Colors.white,
        ),
        child: child,
      ),
    );
  }
}
