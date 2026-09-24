import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/features/registration/ui/views/registration_wizard_screens.dart';

void main() {
  group('a buying source number is looked up only once complete', () {
    test('every form of the same number is complete', () {
      for (final number in [
        '03007781204',
        '923007781204',
        '+923007781204',
        '3007781204',
      ]) {
        expect(isCompleteMobileNumber(number), isTrue, reason: number);
      }
    });

    test('a number still being typed is not', () {
      for (final number in [
        '',
        '0300778120',
        '92300778120',
        '+92300778120',
        '300778120',
      ]) {
        expect(isCompleteMobileNumber(number), isFalse, reason: number);
      }
    });
  });
}
