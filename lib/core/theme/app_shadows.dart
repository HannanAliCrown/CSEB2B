import 'package:flutter/material.dart';

/// Elevation shadows.
///
/// Confirmed against the approved Crown Solar Energy design system
/// (`tokens/elevation.css`, read via the Claude Design MCP on
/// 2026-09-17). Kept deliberately shallow — heavy shadows and blur cost
/// frames on the low-end Android devices this app targets.
abstract final class AppShadows {
  /// --shadow-card: resting cards (e.g. the B1 refused-state card).
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// --shadow-raised: a card raised above the page (e.g. hover/pressed).
  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x140F172A), blurRadius: 20, offset: Offset(0, 6)),
  ];

  /// A dialog/modal floating over dimmed content (e.g. the A4 takeover
  /// confirmation) — matches the design's inline dialog shadow, distinct
  /// from --shadow-sheet (a bottom sheet's upward shadow, not used here).
  static const dialog = <BoxShadow>[
    BoxShadow(color: Color(0x3D0F172A), blurRadius: 32, offset: Offset(0, 12)),
  ];

  static const low = card;
  static const medium = raised;
}
