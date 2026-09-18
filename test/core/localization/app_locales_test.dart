import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/localization/app_locales.dart';

void main() {
  group('AppLocales.directionOf', () {
    test('English reads left to right', () {
      expect(AppLocales.directionOf(AppLocales.english), TextDirection.ltr);
    });

    test('Urdu in Arabic script reads right to left', () {
      expect(AppLocales.directionOf(AppLocales.urdu), TextDirection.rtl);
    });

    test('Roman Urdu reads left to right despite the ur language code', () {
      expect(AppLocales.directionOf(AppLocales.romanUrdu), TextDirection.ltr);
    });
  });
}
