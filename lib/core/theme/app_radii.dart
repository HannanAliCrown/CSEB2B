import 'package:flutter/widgets.dart';

/// Corner radius scale.
///
/// Confirmed against the approved Crown Solar Energy design system
/// (`tokens/radius.css`, read via the Claude Design MCP on 2026-09-17).
abstract final class AppRadii {
  static const sm = 8.0; // --radius-sm
  static const md = 12.0; // --radius-md (also --radius-input)
  static const lg = 16.0; // --radius-lg
  static const hero = 20.0; // --radius-hero
  static const sheet = 24.0; // --radius-sheet (dialogs/bottom sheets)
  static const button = 13.0; // --radius-button
  static const pill = 999.0; // --radius-pill

  static const smRadius = BorderRadius.all(Radius.circular(sm));
  static const mdRadius = BorderRadius.all(Radius.circular(md));
  static const lgRadius = BorderRadius.all(Radius.circular(lg));
  static const heroRadius = BorderRadius.all(Radius.circular(hero));
  static const sheetRadius = BorderRadius.all(Radius.circular(sheet));
  static const buttonRadius = BorderRadius.all(Radius.circular(button));
}
