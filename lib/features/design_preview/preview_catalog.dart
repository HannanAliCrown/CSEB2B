import 'package:flutter/material.dart';

import '../home/ui/models/home_demo_data.dart';
import '../home/ui/views/home_screen.dart';
import '../login/ui/views/crm_authorised_screen.dart';
import '../login/ui/views/device_locked_screen.dart';
import '../login/ui/views/pin_unlock_screen.dart';
import '../login/ui/views/sign_in_screen.dart';
import '../login/ui/views/takeover_screen.dart';
import '../login/ui/views/verify_phone_screen.dart';
import '../registration/ui/views/approval_status_screens.dart';
import '../registration/ui/views/first_launch_screens.dart';
import '../registration/ui/views/registration_cnic_screens.dart';
import '../registration/ui/views/registration_review_screens.dart';
import '../registration/ui/views/registration_source_screens.dart';
import '../registration/ui/views/registration_wizard_screens.dart';
import '../scan/ui/views/scan_prize_screens.dart';
import '../scan/ui/views/scanner_screens.dart';
import '../wallet/ui/views/cash_request_screens.dart';
import '../wallet/ui/views/ledger_screens.dart';
import '../wallet/ui/views/send_cash_screens.dart';

/// One screen in the design, reachable from the preview gallery.
class PreviewScreen {
  const PreviewScreen({
    required this.id,
    required this.title,
    required this.builder,
  });

  /// The design's own screen reference, e.g. `A2`.
  final String id;
  final String title;
  final WidgetBuilder builder;
}

/// One board of the Claude Design document.
class PreviewBoard {
  const PreviewBoard({
    required this.number,
    required this.title,
    required this.screens,
    this.journey = const [],
  });

  final String number;
  final String title;
  final List<PreviewScreen> screens;

  /// The happy path through this board, in order, so it can be clicked
  /// through as one continuous journey.
  final List<WidgetBuilder> journey;
}

/// The first-launch → registration → approval → login → Home journey, in the
/// order a new partner meets it.
const registrationJourney = <WidgetBuilder>[
  _notificationPrompt,
  _selectLanguage,
  _locationPermission,
  _signIn,
  _registrationNumber,
  _registrationRole,
  _registrationDetails,
  _installerMedia,
  _registrationOtp,
  _registrationSource,
  _cnicCapture,
  _cnicReview,
  _cnicNumber,
  _registrationReview,
  _registrationSubmitted,
  _approvalPending,
  _approvalActivated,
  _homeInstaller,
];

/// Every screen built so far, grouped exactly as the design document groups
/// them. Screens carry static demo content only — no services are called.
const previewBoards = <PreviewBoard>[
  PreviewBoard(
    number: '01',
    title: 'First Launch, Registration and Approval',
    journey: registrationJourney,
    screens: [
      PreviewScreen(
        id: 'A1',
        title: 'OS notification prompt',
        builder: _notificationPrompt,
      ),
      PreviewScreen(
        id: 'A2',
        title: 'Select Language',
        builder: _selectLanguage,
      ),
      PreviewScreen(
        id: 'A3',
        title: 'Current location, asked up front',
        builder: _locationPermission,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Location off, explained',
        builder: _locationOff,
      ),
      PreviewScreen(
        id: 'A5',
        title: 'Lands on Login · Register from there',
        builder: _signIn,
      ),
      PreviewScreen(
        id: 'B1',
        title: 'Step 1 · Mobile number',
        builder: _registrationNumber,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'Number already registered',
        builder: _registrationNumberTaken,
      ),
      PreviewScreen(
        id: 'B3',
        title: 'Step 2 · Role selection',
        builder: _registrationRole,
      ),
      PreviewScreen(
        id: 'C1',
        title: 'Step 3 · Details form',
        builder: _registrationDetails,
      ),
      PreviewScreen(
        id: 'C2',
        title: 'Pin drop · market mismatch',
        builder: _registrationPinDrop,
      ),
      PreviewScreen(
        id: 'D1',
        title: 'Step 4 · Installer · video links',
        builder: _installerMedia,
      ),
      PreviewScreen(
        id: 'D2',
        title: 'Step 4 · Retailer · shop images',
        builder: _retailerMedia,
      ),
      PreviewScreen(
        id: 'E1',
        title: 'Step 5 · Enter the code',
        builder: _registrationOtp,
      ),
      PreviewScreen(
        id: 'E2',
        title: 'Wrong code, then rate limit',
        builder: _registrationOtpLocked,
      ),
      PreviewScreen(
        id: 'F1',
        title: 'Step 6 · Buying source',
        builder: _registrationSource,
      ),
      PreviewScreen(
        id: 'F2',
        title: 'Number not found',
        builder: _registrationSourceNotFound,
      ),
      PreviewScreen(
        id: 'G1',
        title: 'Step 7 · CNIC front · camera only',
        builder: _cnicCapture,
      ),
      PreviewScreen(
        id: 'G2',
        title: 'Review, retake, upload progress',
        builder: _cnicReview,
      ),
      PreviewScreen(
        id: 'G3',
        title: 'CNIC number · read from image',
        builder: _cnicNumber,
      ),
      PreviewScreen(
        id: 'H1',
        title: 'Step 8 · Review and submit',
        builder: _registrationReview,
      ),
      PreviewScreen(
        id: 'H2',
        title: 'Submitted · handoff to approval',
        builder: _registrationSubmitted,
      ),
      PreviewScreen(
        id: 'H3',
        title: 'Resume or discard draft',
        builder: _registrationResume,
      ),
      PreviewScreen(
        id: 'I1',
        title: 'Pending · 1 of 3',
        builder: _approvalPending,
      ),
      PreviewScreen(
        id: 'I2',
        title: 'Pending · 2 of 3',
        builder: _approvalPendingTwo,
      ),
      PreviewScreen(id: 'I3', title: 'Activated', builder: _approvalActivated),
      PreviewScreen(
        id: 'I4',
        title: 'Rejected, with reason',
        builder: _approvalRejected,
      ),
    ],
  ),
  PreviewBoard(
    number: '02',
    title: 'Login, Device Binding and App Security',
    screens: [
      PreviewScreen(id: 'A1', title: 'Sign in', builder: _signIn),
      PreviewScreen(
        id: 'A2',
        title: 'New device · SMS code',
        builder: _verifyPhone,
      ),
      PreviewScreen(
        id: 'A3',
        title: 'Wrong code, then lockout',
        builder: _verifyPhoneLocked,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Takeover · another account',
        builder: _takeover,
      ),
      PreviewScreen(
        id: 'B1',
        title: 'Refused · locked to a device',
        builder: _deviceLocked,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'CRM authorised · one move',
        builder: _crmAuthorised,
      ),
      PreviewScreen(
        id: 'B3',
        title: 'Session expired',
        builder: _sessionExpired,
      ),
      PreviewScreen(
        id: 'B4',
        title: 'Account deactivated',
        builder: _accountDeactivated,
      ),
      PreviewScreen(id: 'C1', title: 'PIN unlock', builder: _pinUnlock),
      PreviewScreen(
        id: 'C3',
        title: 'App Security · where the PIN is set',
        builder: _appSecurity,
      ),
    ],
  ),
  PreviewBoard(
    number: '03',
    title: 'Home Dashboard and Navigation',
    screens: [
      PreviewScreen(
        id: 'A1',
        title: 'Installer · balance hidden',
        builder: _homeInstaller,
      ),
      PreviewScreen(
        id: 'A2',
        title: 'Retailer · balance revealed',
        builder: _homeRetailer,
      ),
      PreviewScreen(
        id: 'A3',
        title: 'Wholesaler · ticker only',
        builder: _homeWholesaler,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Distributor · recent activity',
        builder: _homeDistributor,
      ),
      PreviewScreen(
        id: 'B1',
        title: 'Cash transactions blocked',
        builder: _homeCashBlocked,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'Points blocked · earning suspended',
        builder: _homePointsBlocked,
      ),
      PreviewScreen(
        id: 'B3',
        title: 'First load · skeleton',
        builder: _homeSkeleton,
      ),
    ],
  ),
  PreviewBoard(
    number: '04',
    title: 'Wallet, Send Cash, Cash Requests and Ledger',
    journey: sendCashJourney,
    screens: [
      PreviewScreen(
        id: 'A1',
        title: 'Choose a recipient · four paths',
        builder: _sendCashRecipient,
      ),
      PreviewScreen(id: 'A1a', title: 'Contacts', builder: _sendCashContacts),
      PreviewScreen(id: 'A1b', title: 'Scan QR', builder: _sendCashScan),
      PreviewScreen(id: 'A1c', title: 'History', builder: _sendCashHistory),
      PreviewScreen(
        id: 'A1d',
        title: 'Search Number',
        builder: _sendCashSearch,
      ),
      PreviewScreen(id: 'A2', title: 'Amount', builder: _sendCashAmount),
      PreviewScreen(
        id: 'A3',
        title: 'Review sheet · the held rule',
        builder: _sendCashReview,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Sent · held, awaiting approval',
        builder: _sendCashSent,
      ),
      PreviewScreen(
        id: 'B1',
        title: 'Processing, offline, duplicate-safe',
        builder: _sendCashProcessing,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'Each refusal names its reason',
        builder: _sendCashRefusals,
      ),
      PreviewScreen(
        id: 'B3',
        title: "Sender's view · held, settled, returned",
        builder: _sentRequests,
      ),
      PreviewScreen(
        id: 'B4',
        title: 'Cash Request inbox · approve or reject',
        builder: _cashRequestInbox,
      ),
      PreviewScreen(id: 'C1', title: 'Ledger', builder: _ledger),
      PreviewScreen(
        id: 'C2',
        title: 'Filter sheet and date range',
        builder: _ledgerFilter,
      ),
      PreviewScreen(
        id: 'C3',
        title: 'PDF export · progress, ready, share',
        builder: _ledgerExport,
      ),
      PreviewScreen(
        id: 'C4',
        title: 'Empty, filtered-empty, error',
        builder: _ledgerEmpty,
      ),
    ],
  ),
];

/// Send Cash, end to end: recipient → amount → review → held.
const sendCashJourney = <WidgetBuilder>[
  _sendCashRecipient,
  _sendCashContacts,
  _sendCashAmount,
  _sendCashReview,
  _sendCashSent,
];

/// Resolves `/preview/<board>/<id>` to its screen, e.g. `01`/`B3`. An
/// unknown pair falls back to the gallery's first screen so a mistyped link
/// never dead-ends.
Widget previewScreenFor({required String board, required String screen}) {
  for (final b in previewBoards) {
    if (b.number != board) continue;
    for (final s in b.screens) {
      if (s.id.toUpperCase() == screen.toUpperCase()) {
        return Builder(builder: s.builder);
      }
    }
  }
  return Builder(builder: previewBoards.first.screens.first.builder);
}

// Board 01 — first launch and registration.
Widget _notificationPrompt(BuildContext context) =>
    const NotificationPromptScreen();
Widget _selectLanguage(BuildContext context) => const SelectLanguageScreen();
Widget _locationPermission(BuildContext context) =>
    const LocationPermissionScreen();
Widget _locationOff(BuildContext context) => const LocationOffScreen();
Widget _registrationNumber(BuildContext context) =>
    const RegistrationNumberScreen();
Widget _registrationNumberTaken(BuildContext context) =>
    const RegistrationNumberTakenScreen();
Widget _registrationRole(BuildContext context) => const RegistrationRoleScreen();
Widget _registrationDetails(BuildContext context) =>
    const RegistrationDetailsScreen();
Widget _registrationPinDrop(BuildContext context) =>
    const RegistrationPinDropScreen();
Widget _installerMedia(BuildContext context) =>
    const RegistrationInstallerMediaScreen();
Widget _retailerMedia(BuildContext context) =>
    const RegistrationRetailerMediaScreen();
Widget _registrationOtp(BuildContext context) => const RegistrationOtpScreen();
Widget _registrationOtpLocked(BuildContext context) =>
    const RegistrationOtpLockedScreen();
Widget _registrationSource(BuildContext context) =>
    const RegistrationSourceScreen();
Widget _registrationSourceNotFound(BuildContext context) =>
    const RegistrationSourceNotFoundScreen();
Widget _cnicCapture(BuildContext context) => const CnicCaptureScreen();
Widget _cnicReview(BuildContext context) => const CnicReviewScreen();
Widget _cnicNumber(BuildContext context) => const CnicNumberScreen();
Widget _registrationReview(BuildContext context) =>
    const RegistrationReviewScreen();
Widget _registrationSubmitted(BuildContext context) =>
    const RegistrationSubmittedScreen();
Widget _registrationResume(BuildContext context) =>
    const RegistrationResumeScreen();
Widget _approvalPending(BuildContext context) => const ApprovalPendingScreen();
Widget _approvalPendingTwo(BuildContext context) =>
    const ApprovalPendingScreen(received: 2);
Widget _approvalActivated(BuildContext context) =>
    const ApprovalActivatedScreen();
Widget _approvalRejected(BuildContext context) => const ApprovalRejectedScreen();

// Board 02 — login, device binding, PIN.
Widget _signIn(BuildContext context) => const SignInScreen();
Widget _verifyPhone(BuildContext context) => const VerifyPhoneScreen();
Widget _verifyPhoneLocked(BuildContext context) =>
    const VerifyPhoneLockedScreen();
Widget _takeover(BuildContext context) => const TakeoverScreen();
Widget _deviceLocked(BuildContext context) => const DeviceLockedScreen();
Widget _crmAuthorised(BuildContext context) => const CrmAuthorisedScreen();
Widget _sessionExpired(BuildContext context) => const SessionExpiredScreen();
Widget _accountDeactivated(BuildContext context) =>
    const AccountDeactivatedScreen();
Widget _pinUnlock(BuildContext context) => const PinUnlockScreen();
Widget _appSecurity(BuildContext context) => const AppSecurityScreen();

// Board 04 — Wallet, Send Cash, Cash Requests, Ledger.
Widget _sendCashRecipient(BuildContext context) =>
    const SendCashRecipientScreen();
Widget _sendCashContacts(BuildContext context) => const SendCashContactsScreen();
Widget _sendCashScan(BuildContext context) => const SendCashScanScreen();
Widget _sendCashHistory(BuildContext context) => const SendCashHistoryScreen();
Widget _sendCashSearch(BuildContext context) => const SendCashSearchScreen();
Widget _sendCashAmount(BuildContext context) => const SendCashAmountScreen();
Widget _sendCashReview(BuildContext context) => const SendCashReviewScreen();
Widget _sendCashSent(BuildContext context) => const SendCashSentScreen();
Widget _sendCashProcessing(BuildContext context) =>
    const SendCashProcessingScreen();
Widget _sendCashRefusals(BuildContext context) => const SendCashRefusalsScreen();
Widget _sentRequests(BuildContext context) => const SentRequestsScreen();
Widget _cashRequestInbox(BuildContext context) => const CashRequestInboxScreen();
Widget _ledger(BuildContext context) => const LedgerScreen();
Widget _ledgerFilter(BuildContext context) => const LedgerFilterScreen();
Widget _ledgerExport(BuildContext context) => const LedgerExportScreen();
Widget _ledgerEmpty(BuildContext context) => const LedgerEmptyStatesScreen();

// Board 03 — Home.
Widget _homeInstaller(BuildContext context) =>
    const HomeScreen(demo: HomeDemo.installer);
Widget _homeRetailer(BuildContext context) =>
    const HomeScreen(demo: HomeDemo.retailer);
Widget _homeWholesaler(BuildContext context) =>
    const HomeScreen(demo: HomeDemo.wholesaler);
Widget _homeDistributor(BuildContext context) =>
    const HomeScreen(demo: HomeDemo.distributor);
Widget _homeCashBlocked(BuildContext context) => const HomeCashBlockedScreen();
Widget _homePointsBlocked(BuildContext context) =>
    const HomePointsBlockedScreen();
Widget _homeSkeleton(BuildContext context) => const HomeSkeletonScreen();
