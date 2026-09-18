import 'package:flutter/material.dart';

import '../branding/ui/views/branding_request_screens.dart';
import '../branding/ui/views/branding_screens.dart';
import '../complaints/ui/views/complaints_screens.dart';
import '../complaints/ui/views/notification_screens.dart';
import '../home/ui/models/home_demo_data.dart';
import 'ui/views/locale_and_access_screens.dart';
import '../inaam_baazar/ui/views/scheme_screens.dart';
import '../inaam_baazar/ui/views/spin_screens.dart';
import '../home/ui/views/home_screen.dart';
import '../login/ui/views/crm_authorised_screen.dart';
import '../login/ui/views/device_locked_screen.dart';
import '../login/ui/views/pin_unlock_screen.dart';
import '../login/ui/views/sign_in_screen.dart';
import '../login/ui/views/takeover_screen.dart';
import '../login/ui/views/verify_phone_screen.dart';
import '../profile/ui/views/profile_screens.dart';
import '../profile/ui/views/settings_screens.dart';
import '../registration/ui/views/approval_status_screens.dart';
import '../registration/ui/views/first_launch_screens.dart';
import '../registration/ui/views/registration_cnic_screens.dart';
import '../registration/ui/views/registration_review_screens.dart';
import '../registration/ui/views/registration_source_screens.dart';
import '../registration/ui/views/registration_wizard_screens.dart';
import '../points/ui/views/points_screens.dart';
import '../points/ui/views/target_screens.dart';
import '../scan/ui/views/scan_prize_screens.dart';
import '../scan/ui/views/scanner_screens.dart';
import '../space/ui/views/chat_screens.dart';
import '../space/ui/views/space_screens.dart';
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
  PreviewBoard(
    number: '05',
    title: 'Scan QR — Authenticity Check and Scan to Earn',
    screens: [
      PreviewScreen(
        id: 'A1',
        title: 'Installer and Retailer · two tabs',
        builder: _scanEarn,
      ),
      PreviewScreen(
        id: 'A2',
        title: 'Wholesaler and Distributor · one capability',
        builder: _authenticityCheck,
      ),
      PreviewScreen(id: 'A3', title: 'Camera denied', builder: _scanDenied),
      PreviewScreen(id: 'A4', title: 'Genuine product', builder: _scanGenuine),
      PreviewScreen(
        id: 'B1',
        title: 'Not recognised · safe generic',
        builder: _scanNotRecognised,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'In processing · blocked · expired',
        builder: _scanNonPaying,
      ),
      PreviewScreen(
        id: 'B3',
        title: 'Prize credited',
        builder: _scanPrizeCredited,
      ),
      PreviewScreen(
        id: 'B4',
        title: 'Held for review',
        builder: _scanHeldForReview,
      ),
      PreviewScreen(
        id: 'C1',
        title: 'Already claimed for your class',
        builder: _scanAlreadyClaimed,
      ),
      PreviewScreen(
        id: 'C2',
        title: 'Dispute complaint · pre-filled',
        builder: _scanDispute,
      ),
      PreviewScreen(
        id: 'C3',
        title: 'Dispute submitted, then resolved',
        builder: _scanDisputeSubmitted,
      ),
      PreviewScreen(
        id: 'C4',
        title: 'Duplicate submission and retry',
        builder: _scanRetrySafe,
      ),
    ],
  ),
  PreviewBoard(
    number: '06',
    title: 'Points and Targets',
    screens: [
      PreviewScreen(id: 'A1', title: 'Points hub', builder: _pointsHub),
      PreviewScreen(
        id: 'A2',
        title: 'Send Points · three paths only',
        builder: _sendPointsRecipient,
      ),
      PreviewScreen(
        id: 'A3',
        title: 'Confirm · immediate, no approval',
        builder: _sendPointsConfirm,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Sent · and the refusals',
        builder: _sendPointsSent,
      ),
      PreviewScreen(
        id: 'B1',
        title: 'View Target · in progress',
        builder: _targetsInProgress,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'Annual target passed',
        builder: _targetPassed,
      ),
      PreviewScreen(
        id: 'B3',
        title: 'After the CRM conversation',
        builder: _targetAssigned,
      ),
      PreviewScreen(id: 'B4', title: 'No scheme signed', builder: _noScheme),
    ],
  ),
  PreviewBoard(
    number: '07',
    title: 'Shop Branding',
    screens: [
      PreviewScreen(
        id: 'A1',
        title: 'Module landing',
        builder: _brandingLanding,
      ),
      PreviewScreen(id: 'A2', title: 'Request form', builder: _brandingForm),
      PreviewScreen(
        id: 'A3',
        title: 'Board type · Retailer',
        builder: _brandingBoardType,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Installer · Frontlit needs a scan',
        builder: _brandingInstaller,
      ),
      PreviewScreen(
        id: 'A5',
        title: 'Replacement detected · one option',
        builder: _brandingReplacement,
      ),
      PreviewScreen(
        id: 'A6',
        title: 'Request Summary',
        builder: _brandingSummary,
      ),
      PreviewScreen(
        id: 'A7',
        title: 'Past Requests',
        builder: _brandingPastRequests,
      ),
      PreviewScreen(
        id: 'A8',
        title: 'Past request detail · completed',
        builder: _brandingCompleted,
      ),
      PreviewScreen(
        id: 'A9',
        title: 'Past request detail · rejected',
        builder: _brandingRejected,
      ),
    ],
  ),
  PreviewBoard(
    number: '08',
    title: 'Complaints, Notifications and Deep Links',
    screens: [
      PreviewScreen(id: 'A1', title: 'My Complaints', builder: _complaints),
      PreviewScreen(
        id: 'A2',
        title: 'New complaint · type and priority',
        builder: _newComplaint,
      ),
      PreviewScreen(
        id: 'A3',
        title: 'Title, detail, review',
        builder: _complaintReview,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Complaint detail · history and targets',
        builder: _complaintDetail,
      ),
      PreviewScreen(
        id: 'B1',
        title: 'Push banners · lock screen',
        builder: _pushBanners,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'Notification centre · optional',
        builder: _notificationCentre,
      ),
    ],
  ),
  PreviewBoard(
    number: '09',
    title: 'Inaam Baazar — Installer Rewards',
    screens: [
      PreviewScreen(
        id: 'A1',
        title: 'Inaam hub · two spins waiting',
        builder: _inaamHub,
      ),
      PreviewScreen(
        id: 'A2',
        title: 'Result · credited to wallet',
        builder: _spinResult,
      ),
      PreviewScreen(
        id: 'A3',
        title: 'No spins · already used · offline',
        builder: _spinUnavailable,
      ),
      PreviewScreen(id: 'A4', title: 'Reward Program', builder: _rewardProgram),
      PreviewScreen(
        id: 'B1',
        title: 'Scan-based scheme · Silver unlocked',
        builder: _scanScheme,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'Amount-based scheme',
        builder: _amountScheme,
      ),
      PreviewScreen(
        id: 'B3',
        title: 'Claim confirmation',
        builder: _schemeClaimConfirm,
      ),
      PreviewScreen(
        id: 'B4',
        title: 'Claimed · other tiers closed',
        builder: _schemeClaimed,
      ),
      PreviewScreen(
        id: 'B5',
        title: 'Retired feature and open items',
        builder: _inaamNotes,
      ),
    ],
  ),
  PreviewBoard(
    number: '10',
    title: 'Space and Chat',
    screens: [
      PreviewScreen(id: 'A1', title: 'Feed', builder: _spaceFeed),
      PreviewScreen(
        id: 'A2',
        title: 'Post detail · comments and replies',
        builder: _spacePost,
      ),
      PreviewScreen(
        id: 'A3',
        title: 'Space · empty, loading, offline',
        builder: _spaceEmpty,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Chat list · All, Read, Unread',
        builder: _chatList,
      ),
      PreviewScreen(
        id: 'B1',
        title: 'New conversation',
        builder: _newConversation,
      ),
      PreviewScreen(
        id: 'B2',
        title: 'Conversation · text, media, receipts',
        builder: _conversation,
      ),
      PreviewScreen(
        id: 'B3',
        title: 'Connection and blocked recipient',
        builder: _conversationBlocked,
      ),
      PreviewScreen(
        id: 'B4',
        title: 'Unread tab and empty chat',
        builder: _chatListEmpty,
      ),
    ],
  ),
  PreviewBoard(
    number: '11',
    title: 'Profile and Settings',
    screens: [
      PreviewScreen(id: '1', title: 'Profile · Retailer', builder: _profile),
      PreviewScreen(id: '2', title: 'My QR code', builder: _myQrCode),
      PreviewScreen(
        id: '3',
        title: 'Sync Contacts · permission, progress',
        builder: _syncContacts,
      ),
      PreviewScreen(id: '4', title: 'Language', builder: _languageSetting),
      PreviewScreen(id: '5', title: 'Colour Theme', builder: _themeSetting),
      PreviewScreen(id: '6', title: 'App Security', builder: _appSecurity),
      PreviewScreen(
        id: '7',
        title: 'Confirm current PIN',
        builder: _confirmPin,
      ),
      PreviewScreen(id: '8', title: 'Set PIN · confirmed', builder: _setPin),
      PreviewScreen(id: '9', title: 'PIN removed', builder: _pinRemoved),
      PreviewScreen(id: '10', title: 'PIN enabled', builder: _pinEnabled),
      PreviewScreen(id: '11', title: 'Sign out', builder: _signOut),
    ],
  ),
  PreviewBoard(
    number: '12',
    title: 'Urdu RTL, Dark Mode, Accessibility',
    screens: [
      PreviewScreen(id: 'A1', title: 'Urdu · RTL mirrored', builder: _urduHome),
      PreviewScreen(
        id: 'A2',
        title: 'Roman Urdu · dark theme',
        builder: _romanUrduDark,
      ),
      PreviewScreen(
        id: 'A3',
        title: 'Largest system font',
        builder: _largeFont,
      ),
      PreviewScreen(
        id: 'A4',
        title: 'Accessibility and non-colour status',
        builder: _accessibility,
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
Widget _registrationRole(BuildContext context) =>
    const RegistrationRoleScreen();
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
Widget _approvalRejected(BuildContext context) =>
    const ApprovalRejectedScreen();

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
Widget _sendCashContacts(BuildContext context) =>
    const SendCashContactsScreen();
Widget _sendCashScan(BuildContext context) => const SendCashScanScreen();
Widget _sendCashHistory(BuildContext context) => const SendCashHistoryScreen();
Widget _sendCashSearch(BuildContext context) => const SendCashSearchScreen();
Widget _sendCashAmount(BuildContext context) => const SendCashAmountScreen();
Widget _sendCashReview(BuildContext context) => const SendCashReviewScreen();
Widget _sendCashSent(BuildContext context) => const SendCashSentScreen();
Widget _sendCashProcessing(BuildContext context) =>
    const SendCashProcessingScreen();
Widget _sendCashRefusals(BuildContext context) =>
    const SendCashRefusalsScreen();
Widget _sentRequests(BuildContext context) => const SentRequestsScreen();
Widget _cashRequestInbox(BuildContext context) =>
    const CashRequestInboxScreen();
Widget _ledger(BuildContext context) => const LedgerScreen();
Widget _ledgerFilter(BuildContext context) => const LedgerFilterScreen();
Widget _ledgerExport(BuildContext context) => const LedgerExportScreen();
Widget _ledgerEmpty(BuildContext context) => const LedgerEmptyStatesScreen();

// Board 12 — RTL, dark and accessibility.
Widget _urduHome(BuildContext context) => const UrduHomeScreen();
Widget _romanUrduDark(BuildContext context) => const RomanUrduDarkScreen();
Widget _largeFont(BuildContext context) => const LargeFontScreen();
Widget _accessibility(BuildContext context) => const AccessibilityRulesScreen();

// Board 11 — Profile and Settings.
Widget _profile(BuildContext context) => const ProfileScreen();
Widget _myQrCode(BuildContext context) => const MyQrCodeScreen();
Widget _syncContacts(BuildContext context) => const SyncContactsScreen();
Widget _languageSetting(BuildContext context) => const LanguageSettingScreen();
Widget _themeSetting(BuildContext context) => const ThemeSettingScreen();
Widget _confirmPin(BuildContext context) => const ConfirmPinScreen();
Widget _setPin(BuildContext context) => const SetPinScreen();
Widget _pinRemoved(BuildContext context) =>
    const PinResultScreen(enabled: false);
Widget _pinEnabled(BuildContext context) =>
    const PinResultScreen(enabled: true);
Widget _signOut(BuildContext context) => const SignOutScreen();

// Board 10 — Space and Chat.
Widget _spaceFeed(BuildContext context) => const SpaceFeedScreen();
Widget _spacePost(BuildContext context) => const SpacePostDetailScreen();
Widget _spaceEmpty(BuildContext context) => const SpaceEmptyStatesScreen();
Widget _chatList(BuildContext context) => const ChatListScreen();
Widget _chatListEmpty(BuildContext context) =>
    const ChatListScreen(empty: true);
Widget _newConversation(BuildContext context) => const NewConversationScreen();
Widget _conversation(BuildContext context) => const ConversationScreen();
Widget _conversationBlocked(BuildContext context) =>
    const ConversationBlockedScreen();

// Board 09 — Inaam Baazar.
Widget _inaamHub(BuildContext context) => const InaamHubScreen();
Widget _spinResult(BuildContext context) => const SpinResultScreen();
Widget _spinUnavailable(BuildContext context) => const SpinUnavailableScreen();
Widget _rewardProgram(BuildContext context) => const RewardProgramScreen();
Widget _scanScheme(BuildContext context) => const ScanSchemeScreen();
Widget _amountScheme(BuildContext context) => const AmountSchemeScreen();
Widget _schemeClaimConfirm(BuildContext context) =>
    const SchemeClaimConfirmScreen();
Widget _schemeClaimed(BuildContext context) => const SchemeClaimedScreen();
Widget _inaamNotes(BuildContext context) => const InaamDesignNotesScreen();

// Board 08 — Complaints and Notifications.
Widget _complaints(BuildContext context) => const ComplaintsListScreen();
Widget _newComplaint(BuildContext context) => const NewComplaintScreen();
Widget _complaintReview(BuildContext context) => const ComplaintReviewScreen();
Widget _complaintDetail(BuildContext context) => const ComplaintDetailScreen();
Widget _pushBanners(BuildContext context) => const PushBannersScreen();
Widget _notificationCentre(BuildContext context) =>
    const NotificationCentreScreen();

// Board 07 — Shop Branding.
Widget _brandingLanding(BuildContext context) => const BrandingLandingScreen();
Widget _brandingForm(BuildContext context) => const BrandingRequestFormScreen();
Widget _brandingBoardType(BuildContext context) =>
    const BrandingBoardTypeScreen();
Widget _brandingInstaller(BuildContext context) =>
    const BrandingInstallerScreen();
Widget _brandingReplacement(BuildContext context) =>
    const BrandingReplacementScreen();
Widget _brandingSummary(BuildContext context) =>
    const BrandingRequestSummaryScreen();
Widget _brandingPastRequests(BuildContext context) =>
    const BrandingPastRequestsScreen();
Widget _brandingCompleted(BuildContext context) =>
    const BrandingCompletedScreen();
Widget _brandingRejected(BuildContext context) =>
    const BrandingRejectedScreen();

// Board 06 — Points and Targets.
Widget _pointsHub(BuildContext context) => const PointsHubScreen();
Widget _sendPointsRecipient(BuildContext context) =>
    const SendPointsRecipientScreen();
Widget _sendPointsConfirm(BuildContext context) =>
    const SendPointsConfirmScreen();
Widget _sendPointsSent(BuildContext context) => const SendPointsSentScreen();
Widget _targetsInProgress(BuildContext context) =>
    const TargetsInProgressScreen();
Widget _targetPassed(BuildContext context) => const TargetPassedScreen();
Widget _targetAssigned(BuildContext context) => const TargetAssignedScreen();
Widget _noScheme(BuildContext context) => const NoSchemeScreen();

// Board 05 — Scan QR.
Widget _scanEarn(BuildContext context) => const ScanEarnScreen();
Widget _authenticityCheck(BuildContext context) =>
    const AuthenticityCheckScreen();
Widget _scanDenied(BuildContext context) => const ScanCameraDeniedScreen();
Widget _scanGenuine(BuildContext context) => const ScanGenuineScreen();
Widget _scanNotRecognised(BuildContext context) =>
    const ScanNotRecognisedScreen();
Widget _scanNonPaying(BuildContext context) =>
    const ScanNonPayingStatesScreen();
Widget _scanPrizeCredited(BuildContext context) =>
    const ScanPrizeCreditedScreen();
Widget _scanHeldForReview(BuildContext context) =>
    const ScanHeldForReviewScreen();
Widget _scanAlreadyClaimed(BuildContext context) =>
    const ScanAlreadyClaimedScreen();
Widget _scanDispute(BuildContext context) => const ScanDisputeScreen();
Widget _scanDisputeSubmitted(BuildContext context) =>
    const ScanDisputeSubmittedScreen();
Widget _scanRetrySafe(BuildContext context) => const ScanRetrySafeScreen();

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
