// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Crown Solar Energy';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String get routeNotFoundMessage => 'The requested route does not exist.';

  @override
  String get authMobileNumberLabel => 'Registered mobile number';

  @override
  String get authMobileNumberHint => 'e.g. +923001234567';

  @override
  String get authKeepSignedIn => 'Keep me signed in';

  @override
  String get authContinueAction => 'Continue';

  @override
  String get authAccountNotFound =>
      'We couldn\'t find an account with that mobile number.';

  @override
  String get authSignInHeading => 'Sign in';

  @override
  String get authSignInSubtitle =>
      'Use the mobile number registered with Crown Solar.';

  @override
  String get authDevicePolicyNotice =>
      'Your account works on one phone at a time. Signing in on a new phone needs an SMS code.';

  @override
  String get authSignInAction => 'Sign In';

  @override
  String get authRegisterPrompt => 'New to Crown Solar?';

  @override
  String get authRegisterAction => 'Register';

  @override
  String get registrationTitle => 'Register this device';

  @override
  String get registrationOtpPrompt =>
      'Enter the verification code sent to your mobile number to activate this device.';

  @override
  String get registrationAlreadyRegistered =>
      'This account already has an active device. Try signing in instead.';

  @override
  String get registrationSuccess =>
      'Registration complete. This device is now active for your account.';

  @override
  String get registrationFailed =>
      'Registration could not be completed. Please try again.';

  @override
  String get otpCodeLabel => 'Verification code';

  @override
  String get otpVerifyAction => 'Verify';

  @override
  String get otpInvalidCode => 'That code isn\'t correct. Please try again.';

  @override
  String otpPrototypeCodeNotice(String code) {
    return 'Prototype only — verification code: $code';
  }

  @override
  String get otpEnterCodeTitle => 'Enter the 6-digit code';

  @override
  String otpSentTo(String number) {
    return 'Sent by SMS to $number. This is a new phone, so we verify it before signing you in.';
  }

  @override
  String get otpResendAction => 'Resend code';

  @override
  String get otpVerifyAndSignInAction => 'Verify and Sign In';

  @override
  String get loginNewDeviceNotice =>
      'This isn\'t your account\'s usual device. Enter the verification code we sent to confirm it\'s you.';

  @override
  String get loginTrustedSuccess => 'Signed in.';

  @override
  String get loginSecondDeviceMoveNotice =>
      'This is your account\'s first device move since registration. Any move after this will need Crown Solar CRM authorization.';

  @override
  String get loginAuthorizationPending =>
      'Your request to use this device is awaiting authorization. Please check back shortly.';

  @override
  String get loginAuthorizationRetry => 'Check again';

  @override
  String get loginAuthorizationNotAuthorized =>
      'This device hasn\'t been authorized to use your account. Your other device remains active.';

  @override
  String get loginRebindingSuccess =>
      'This device is now active for your account.';

  @override
  String get loginRebindingFailed =>
      'We couldn\'t switch your account to this device. Please try again.';

  @override
  String get loginDeviceLockedTitle => 'Your account is fixed to another phone';

  @override
  String get loginDeviceLockedBody =>
      'You have already moved your account once. Your other phone keeps working normally — nothing is blocked or suspended there.';

  @override
  String get loginCrmHelpTitle => 'If you cannot use that phone';

  @override
  String get loginCrmHelpBody =>
      'Lost, stolen, sold or broken — Crown Solar CRM can allow a move to a new phone. They will ask what happened and record it.';

  @override
  String get loginCallCrmAction => 'Call CRM';

  @override
  String get loginNoPasswordResetNotice =>
      'This is not a password problem, so no password reset is offered here.';

  @override
  String get loginCrmAuthorizedTitle =>
      'Crown Solar CRM has authorized this move';

  @override
  String get loginCrmAuthorizedBody =>
      'Verify this phone to complete the move.';

  @override
  String get loginOneMoveOnlyNotice =>
      'This authorization covers one move only. Once this phone is verified, your account locks to it again.';

  @override
  String get loginOldDeviceSignOutNotice =>
      'Your old phone will be signed out and will no longer be able to open your account.';

  @override
  String get loginSessionExpiredNotice =>
      'You were signed out because your session ended. Sign in again to continue — this is not a device change, and no code is needed on this phone.';

  @override
  String get loginDeviceConflictTitle =>
      'This phone is signed in to another account';

  @override
  String get loginDeviceConflictBody =>
      'Continuing will sign that other account out of this phone and move your account here. The other account is not deleted — they can sign back in on their own phone.';

  @override
  String get loginDeviceConflictConfirm => 'Continue and Verify';

  @override
  String get loginDeviceConflictCancel => 'Cancel';

  @override
  String get homeWelcomeMessage => 'You\'re signed in.';

  @override
  String get homeLogoutAction => 'Sign out';
}
