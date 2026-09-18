import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
    Locale.fromSubtags(languageCode: 'ur', scriptCode: 'Latn'),
  ];

  /// Application name shown in the OS task switcher and app bars.
  ///
  /// In en, this message translates to:
  /// **'Crown Solar Energy'**
  String get appTitle;

  /// Title of the router error screen.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeNotFoundTitle;

  /// Body of the router error screen.
  ///
  /// In en, this message translates to:
  /// **'The requested route does not exist.'**
  String get routeNotFoundMessage;

  /// Label for the mobile number input shared by registration and login.
  ///
  /// In en, this message translates to:
  /// **'Registered mobile number'**
  String get authMobileNumberLabel;

  /// Placeholder hint for the mobile number input.
  ///
  /// In en, this message translates to:
  /// **'e.g. +923001234567'**
  String get authMobileNumberHint;

  /// Label for the Keep Me Signed In checkbox on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in'**
  String get authKeepSignedIn;

  /// Primary action button on login/registration mobile-number entry.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinueAction;

  /// Shown when the submitted mobile number has no matching account.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an account with that mobile number.'**
  String get authAccountNotFound;

  /// Heading on the Login screen (Claude Design A1).
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInHeading;

  /// Subtitle under the Sign in heading (Claude Design A1).
  ///
  /// In en, this message translates to:
  /// **'Use the mobile number registered with Crown Solar.'**
  String get authSignInSubtitle;

  /// Persistent device-binding policy banner on the Login screen (Claude Design A1), stated up front so the OTP screen is never a surprise.
  ///
  /// In en, this message translates to:
  /// **'Your account works on one phone at a time. Signing in on a new phone needs an SMS code.'**
  String get authDevicePolicyNotice;

  /// Primary action on the Login screen and the session-expired screen (Claude Design A1, B3).
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignInAction;

  /// Prefix text before the Register link on the Login screen (Claude Design A1). Registration itself is a separate feature.
  ///
  /// In en, this message translates to:
  /// **'New to Crown Solar?'**
  String get authRegisterPrompt;

  /// Link text that navigates to the existing Registration screen (Claude Design A1).
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterAction;

  /// Title of the registration screen.
  ///
  /// In en, this message translates to:
  /// **'Register this device'**
  String get registrationTitle;

  /// Instructional copy shown once a registration OTP has been requested.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your mobile number to activate this device.'**
  String get registrationOtpPrompt;

  /// Shown when registration is attempted for an account that already has an Active device.
  ///
  /// In en, this message translates to:
  /// **'This account already has an active device. Try signing in instead.'**
  String get registrationAlreadyRegistered;

  /// Shown after a successful registration and initial device binding.
  ///
  /// In en, this message translates to:
  /// **'Registration complete. This device is now active for your account.'**
  String get registrationSuccess;

  /// Shown when registration OTP verification succeeds but the device could not be activated.
  ///
  /// In en, this message translates to:
  /// **'Registration could not be completed. Please try again.'**
  String get registrationFailed;

  /// Label for the OTP entry field, shared by registration and login-context OTP.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpCodeLabel;

  /// Button that submits an OTP code for verification.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyAction;

  /// Shown when an OTP submission does not match the issued code.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t correct. Please try again.'**
  String get otpInvalidCode;

  /// Prototype-only notice surfacing the simulated OTP value; never present in production, since no real SMS provider exists yet.
  ///
  /// In en, this message translates to:
  /// **'Prototype only — verification code: {code}'**
  String otpPrototypeCodeNotice(String code);

  /// Heading on the login-context OTP entry screen (Claude Design A2/A3/B2).
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get otpEnterCodeTitle;

  /// Subtitle naming the destination of the login-context OTP (Claude Design A2).
  ///
  /// In en, this message translates to:
  /// **'Sent by SMS to {number}. This is a new phone, so we verify it before signing you in.'**
  String otpSentTo(String number);

  /// Action that re-requests a login-context OTP (Claude Design A2/B2 "Resend"). No cooldown/countdown is implemented, since none is defined by the business.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendAction;

  /// Primary action on the login-context OTP entry screen (Claude Design A2/B2).
  ///
  /// In en, this message translates to:
  /// **'Verify and Sign In'**
  String get otpVerifyAndSignInAction;

  /// Shown when the current device is classified New/Untrusted during login.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t your account\'s usual device. Enter the verification code we sent to confirm it\'s you.'**
  String get loginNewDeviceNotice;

  /// Shown after a successful trusted-device sign-in.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get loginTrustedSuccess;

  /// Second-device-tier info banner on the OTP entry screen (Claude Design A2) — states the consequence before the user commits. Deliberately does not use the design's literal "one free move" phrasing; see spec.md's exact required terminology.
  ///
  /// In en, this message translates to:
  /// **'This is your account\'s first device move since registration. Any move after this will need Crown Solar CRM authorization.'**
  String get loginSecondDeviceMoveNotice;

  /// Shown while rebinding authorization has not yet been resolved.
  ///
  /// In en, this message translates to:
  /// **'Your request to use this device is awaiting authorization. Please check back shortly.'**
  String get loginAuthorizationPending;

  /// Button that re-checks rebinding authorization status.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get loginAuthorizationRetry;

  /// Shown when rebinding authorization resolves to Not Authorized.
  ///
  /// In en, this message translates to:
  /// **'This device hasn\'t been authorized to use your account. Your other device remains active.'**
  String get loginAuthorizationNotAuthorized;

  /// Shown after a successful, authorized rebinding.
  ///
  /// In en, this message translates to:
  /// **'This device is now active for your account.'**
  String get loginRebindingSuccess;

  /// Shown when an authorized rebinding attempt fails to complete.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t switch your account to this device. Please try again.'**
  String get loginRebindingFailed;

  /// Heading on the third-or-later-tier refused state (Claude Design B1), shown for both Pending and Not Authorized outcomes.
  ///
  /// In en, this message translates to:
  /// **'Your account is fixed to another phone'**
  String get loginDeviceLockedTitle;

  /// Body copy on the B1 refused state. Deliberately does not name the other device (e.g. by masked number), since that identifier is not exposed by the current AuthService contract.
  ///
  /// In en, this message translates to:
  /// **'You have already moved your account once. Your other phone keeps working normally — nothing is blocked or suspended there.'**
  String get loginDeviceLockedBody;

  /// Secondary card heading on the B1 refused state.
  ///
  /// In en, this message translates to:
  /// **'If you cannot use that phone'**
  String get loginCrmHelpTitle;

  /// Secondary card body on the B1 refused state.
  ///
  /// In en, this message translates to:
  /// **'Lost, stolen, sold or broken — Crown Solar CRM can allow a move to a new phone. They will ask what happened and record it.'**
  String get loginCrmHelpBody;

  /// Button on the B1 refused state. This app never implements CRM screens itself (FR-029) — this is a contact action only.
  ///
  /// In en, this message translates to:
  /// **'Call CRM'**
  String get loginCallCrmAction;

  /// Footnote on the B1 refused state clarifying why no password-reset action exists.
  ///
  /// In en, this message translates to:
  /// **'This is not a password problem, so no password reset is offered here.'**
  String get loginNoPasswordResetNotice;

  /// Success-tone banner heading on the third-or-later-tier authorized OTP screen (Claude Design B2).
  ///
  /// In en, this message translates to:
  /// **'Crown Solar CRM has authorized this move'**
  String get loginCrmAuthorizedTitle;

  /// Success-tone banner body on the B2 authorized OTP screen. Does not state an authorization timestamp, since none is exposed by the current AuthService contract.
  ///
  /// In en, this message translates to:
  /// **'Verify this phone to complete the move.'**
  String get loginCrmAuthorizedBody;

  /// Info row on the B2 authorized OTP screen.
  ///
  /// In en, this message translates to:
  /// **'This authorization covers one move only. Once this phone is verified, your account locks to it again.'**
  String get loginOneMoveOnlyNotice;

  /// Info row on the B2 authorized OTP screen.
  ///
  /// In en, this message translates to:
  /// **'Your old phone will be signed out and will no longer be able to open your account.'**
  String get loginOldDeviceSignOutNotice;

  /// Info banner on the session-expired sign-in screen (Claude Design B3).
  ///
  /// In en, this message translates to:
  /// **'You were signed out because your session ended. Sign in again to continue — this is not a device change, and no code is needed on this phone.'**
  String get loginSessionExpiredNotice;

  /// Heading of the A4 takeover-confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This phone is signed in to another account'**
  String get loginDeviceConflictTitle;

  /// Body of the A4 dialog. Does not name the other account by display name/role, since AuthService's conflict outcome currently exposes only an account id — see the implementation report.
  ///
  /// In en, this message translates to:
  /// **'Continuing will sign that other account out of this phone and move your account here. The other account is not deleted — they can sign back in on their own phone.'**
  String get loginDeviceConflictBody;

  /// Primary button on the A4 dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue and Verify'**
  String get loginDeviceConflictConfirm;

  /// Secondary button on the A4 dialog. Declining performs no writes at all (FR-014).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get loginDeviceConflictCancel;

  /// Placeholder authenticated-home message; not final CSE product UI.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in.'**
  String get homeWelcomeMessage;

  /// Button that ends the local session without unbinding the device.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get homeLogoutAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'ur':
      {
        switch (locale.scriptCode) {
          case 'Latn':
            return AppLocalizationsUrLatn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
