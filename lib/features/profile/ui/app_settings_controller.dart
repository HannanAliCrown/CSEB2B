import 'package:flutter/material.dart';

import '../../../core/localization/app_locales.dart';
import '../data/profile_settings_service.dart';

/// The two choices that change how the whole app looks: the colour theme and
/// the language.
///
/// Held above `MaterialApp` so changing either rebuilds everything at once,
/// rather than each screen reading a preference of its own.
///
/// This is the app's live copy. The database is where the choice is kept, and
/// it is reapplied here whenever a partner signs in.
class AppSettingsController extends ChangeNotifier {
  /// Null means follow the phone, which is what a fresh install does.
  ThemeMode themeMode = ThemeMode.system;

  /// Null means follow the phone's own language.
  Locale? locale;

  static Locale localeFor(AppLanguage language) => switch (language) {
    AppLanguage.english => AppLocales.english,
    AppLanguage.urdu => AppLocales.urdu,
    AppLanguage.romanUrdu => AppLocales.romanUrdu,
  };

  /// Puts the partner's saved choices into effect. Called on sign-in, and
  /// again each time one of them is changed.
  void apply(ProfileSettings settings) {
    themeMode = settings.themeMode;
    locale = settings.language == null ? null : localeFor(settings.language!);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (themeMode == mode) return;
    themeMode = mode;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    final next = localeFor(language);
    if (locale == next) return;
    locale = next;
    notifyListeners();
  }

  /// Back to following the phone — what signing out leaves behind, so the
  /// next partner does not inherit the last one's choices.
  void reset() {
    themeMode = ThemeMode.system;
    locale = null;
    notifyListeners();
  }
}
