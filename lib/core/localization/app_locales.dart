import 'package:flutter/widgets.dart';

/// Locale helpers for the application.
///
/// The supported locale list is owned by the generated
/// `AppLocalizations.supportedLocales`; it is not restated here.
///
/// Roman Urdu is modelled as Urdu in the Latin script (`ur-Latn`) so it stays a
/// variant of Urdu rather than a separate language.
abstract final class AppLocales {
  static const english = Locale('en');
  static const urdu = Locale('ur');
  static final romanUrdu = Locale.fromSubtags(
    languageCode: 'ur',
    scriptCode: 'Latn',
  );

  /// Flutter derives text direction from the language code alone, which would
  /// render Roman Urdu right-to-left because its language code is `ur`.
  /// Latin-script Urdu reads left-to-right, so the script code must be honoured.
  static TextDirection directionOf(Locale locale) {
    if (locale.languageCode == 'ur' && locale.scriptCode != 'Latn') {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }
}
