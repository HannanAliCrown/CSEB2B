/// Data-layer models for first launch and the partner registration wizard,
/// mirroring db/migrations/001_first_launch_and_registration.sql.
///
/// Kept apart from `models.dart`, which belongs to the login and
/// device-binding feature. The two share the `accounts` and `devices` tables
/// but answer different questions about them.
library;

/// A market a partner can be placed in. Reference data.
class Market {
  const Market({required this.id, required this.name, required this.city});

  final String id;
  final String name;
  final String city;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'city': city};
}

/// What the registration wizard needs to know about an existing account:
/// enough to say "this number is taken", "this CNIC is taken", or "this is
/// who you buy from".
class PartnerAccountRow {
  const PartnerAccountRow({
    required this.id,
    required this.mobileNumber,
    required this.userType,
    required this.displayName,
    required this.contactName,
    required this.marketName,
    required this.cnicNumber,
  });

  final String id;
  final String mobileNumber;

  /// 'installer' | 'retailer' | 'wholesaler' | 'distributor'.
  final String userType;

  final String? displayName;
  final String? contactName;
  final String? marketName;
  final String? cnicNumber;

  Map<String, Object?> toJson() => {
    'id': id,
    'mobileNumber': mobileNumber,
    'userType': userType,
    'displayName': displayName,
    'contactName': contactName,
    'marketName': marketName,
  };
}

/// Where one of the three approvals stands.
class ApprovalRow {
  const ApprovalRow({
    required this.approver,
    required this.state,
    this.decidedByName,
    this.decidedAt,
  });

  /// 'buying_source' | 'marketing_officer' | 'crm'.
  final String approver;

  /// 'outstanding' | 'approved' | 'rejected'.
  final String state;

  final String? decidedByName;
  final DateTime? decidedAt;

  Map<String, Object?> toJson() => {
    'approver': approver,
    'state': state,
    'decidedByName': decidedByName,
    'decidedAt': decidedAt?.toIso8601String(),
  };
}

/// A submitted application and where its approvals stand.
class ApplicationRow {
  const ApplicationRow({
    required this.id,
    required this.reference,
    required this.mobileNumber,
    required this.status,
    required this.submittedAt,
    required this.verifyingSourceName,
    required this.approvals,
    this.businessName,
    this.contactName,
    this.role,
    this.marketName,
  });

  final String id;
  final String reference;
  final String mobileNumber;

  /// 'submitted' | 'approved' | 'rejected' | 'withdrawn'.
  final String status;

  final DateTime submittedAt;

  /// The first buying source named — the one asked to verify the
  /// application. Null when the number resolved to nothing.
  final String? verifyingSourceName;

  final List<ApprovalRow> approvals;

  // Who the application is for. Carried on the application itself, because an
  // applicant signs in to watch their approvals before any account exists to
  // read a name from.
  final String? businessName;
  final String? contactName;

  /// 'installer' or 'retailer'.
  final String? role;

  final String? marketName;

  /// True once every approval is in. Nothing else opens the account.
  bool get fullyApproved =>
      approvals.isNotEmpty && approvals.every((a) => a.state == 'approved');

  Map<String, Object?> toJson() => {
    'id': id,
    'reference': reference,
    'mobileNumber': mobileNumber,
    'status': status,
    'submittedAt': submittedAt.toIso8601String(),
    'verifyingSourceName': verifyingSourceName,
    'businessName': businessName,
    'contactName': contactName,
    'role': role,
    'marketName': marketName,
    'approvals': [for (final approval in approvals) approval.toJson()],
  };
}

/// One buying source named on an application, in the order it was entered.
class BuyingSourceInput {
  const BuyingSourceInput({required this.position, required this.mobileNumber});

  final int position;
  final String mobileNumber;

  static BuyingSourceInput fromJson(Map<String, Object?> json) =>
      BuyingSourceInput(
        position: (json['position'] as num).toInt(),
        mobileNumber: json['mobileNumber']! as String,
      );
}

/// One captured or typed item to file with an application.
class MediaInput {
  const MediaInput({
    required this.kind,
    this.slot,
    this.linkUrl,
    this.storagePath,
  });

  /// 'video_link' | 'shop_image' | 'cnic_front' | 'cnic_back' | 'selfie'.
  final String kind;
  final String? slot;
  final String? linkUrl;
  final String? storagePath;

  static MediaInput fromJson(Map<String, Object?> json) => MediaInput(
    kind: json['kind']! as String,
    slot: json['slot'] as String?,
    linkUrl: json['linkUrl'] as String?,
    storagePath: json['storagePath'] as String?,
  );
}

/// Everything the wizard submits in one call. The application, its buying
/// sources and its media are written together or not at all.
class ApplicationInput {
  const ApplicationInput({
    required this.mobileNumber,
    required this.role,
    required this.fullName,
    required this.businessName,
    required this.businessAddress,
    required this.cnicNumber,
    this.countryCode = '+92',
    this.alternateNumber,
    this.marketName,
    this.shopLatitude,
    this.shopLongitude,
    this.mobileVerified = false,
    this.installationUuid,
    this.buyingSources = const [],
    this.media = const [],
  });

  final String mobileNumber;

  /// 'installer' | 'retailer'. The trade roles are assigned by CRM and can
  /// never arrive this way.
  final String role;

  final String fullName;
  final String businessName;
  final String businessAddress;
  final String cnicNumber;
  final String countryCode;
  final String? alternateNumber;
  final String? marketName;
  final double? shopLatitude;
  final double? shopLongitude;
  final bool mobileVerified;

  /// The phone the application was made on, when it is known.
  final String? installationUuid;

  final List<BuyingSourceInput> buyingSources;
  final List<MediaInput> media;

  static ApplicationInput fromJson(Map<String, Object?> json) =>
      ApplicationInput(
        mobileNumber: json['mobileNumber']! as String,
        role: json['role']! as String,
        fullName: json['fullName']! as String,
        businessName: json['businessName']! as String,
        businessAddress: json['businessAddress']! as String,
        cnicNumber: json['cnicNumber']! as String,
        countryCode: json['countryCode'] as String? ?? '+92',
        alternateNumber: json['alternateNumber'] as String?,
        marketName: json['marketName'] as String?,
        shopLatitude: (json['shopLatitude'] as num?)?.toDouble(),
        shopLongitude: (json['shopLongitude'] as num?)?.toDouble(),
        mobileVerified: json['mobileVerified'] as bool? ?? false,
        installationUuid: json['installationUuid'] as String?,
        buyingSources: [
          for (final entry in (json['buyingSources'] as List? ?? const []))
            BuyingSourceInput.fromJson(entry as Map<String, Object?>),
        ],
        media: [
          for (final entry in (json['media'] as List? ?? const []))
            MediaInput.fromJson(entry as Map<String, Object?>),
        ],
      );
}

/// One slide in Home's slider.
///
/// A slide is a picture with a window it runs for. The eyebrow and headline
/// are optional text over it, so a picture-only slide and a text-only card
/// are both just rows.
class PromoSlideRow {
  const PromoSlideRow({
    required this.id,
    this.imageUrl,
    this.eyebrow,
    this.headline,
  });

  final String id;
  final String? imageUrl;
  final String? eyebrow;
  final String? headline;

  Map<String, Object?> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'eyebrow': eyebrow,
    'headline': headline,
  };
}

/// One announcement in Home's running line, with the colours it runs in.
class TickerMessageRow {
  const TickerMessageRow({
    required this.message,
    this.textColour,
    this.backgroundColour,
  });

  final String message;

  /// '#RRGGBB', or null for the app's own ticker colours.
  final String? textColour;
  final String? backgroundColour;

  Map<String, Object?> toJson() => {
    'message': message,
    'textColour': textColour,
    'backgroundColour': backgroundColour,
  };
}

/// Everything Home shows for one partner.
class DashboardRow {
  const DashboardRow({
    required this.availablePaisa,
    required this.heldPaisa,
    required this.slides,
    required this.ticker,
  });

  /// Paisa, never rupees — money is counted in whole smallest units so no
  /// balance is ever a rounded float.
  final int availablePaisa;

  /// Money that has left the available balance but settled nowhere: the
  /// receiver has not accepted it yet.
  final int heldPaisa;

  final List<PromoSlideRow> slides;
  final List<TickerMessageRow> ticker;

  Map<String, Object?> toJson() => {
    'availablePaisa': availablePaisa,
    'heldPaisa': heldPaisa,
    'slides': [for (final slide in slides) slide.toJson()],
    'ticker': [for (final message in ticker) message.toJson()],
  };
}

/// What first launch settled about this phone.
class DeviceLaunchInput {
  const DeviceLaunchInput({
    required this.installationUuid,
    this.platform,
    this.appVersion,
    this.languageCode,
    this.languageRemembered,
    this.notificationPermission,
    this.locationPermission,
    this.latitude,
    this.longitude,
    this.firstLaunchComplete = false,
  });

  final String installationUuid;
  final String? platform;
  final String? appVersion;

  /// 'en' | 'ur' | 'ur-Latn'.
  final String? languageCode;
  final bool? languageRemembered;

  /// 'granted' | 'denied' | 'permanently_denied' | 'restricted'.
  final String? notificationPermission;
  final String? locationPermission;

  /// Where the phone was, never where the shop is.
  final double? latitude;
  final double? longitude;

  final bool firstLaunchComplete;

  static DeviceLaunchInput fromJson(Map<String, Object?> json) =>
      DeviceLaunchInput(
        installationUuid: json['installationUuid']! as String,
        platform: json['platform'] as String?,
        appVersion: json['appVersion'] as String?,
        languageCode: json['languageCode'] as String?,
        languageRemembered: json['languageRemembered'] as bool?,
        notificationPermission: json['notificationPermission'] as String?,
        locationPermission: json['locationPermission'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        firstLaunchComplete: json['firstLaunchComplete'] as bool? ?? false,
      );
}

/// Why a submission was refused. The wizard has already checked each of
/// these, so these are the last line rather than the first.
enum SubmitRejection { numberTaken, cnicTaken, applicationOpen }

/// The outcome of submitting an application.
class SubmitResult {
  const SubmitResult.accepted(this.application)
    : rejection = null,
      heldBy = null;
  const SubmitResult.rejected(this.rejection, {this.heldBy})
    : application = null;

  final ApplicationRow? application;
  final SubmitRejection? rejection;

  /// The business already holding the number or CNIC, when there is one.
  /// Never shown to the applicant for a CNIC clash — one identity's details
  /// are not another applicant's business.
  final String? heldBy;
}
