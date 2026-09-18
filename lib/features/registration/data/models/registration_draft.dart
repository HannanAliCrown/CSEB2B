/// The role a partner registers as. Wholesaler and Distributor are assigned
/// by Crown Solar CRM — they are never self-selected here.
enum RegistrationRole { installer, retailer }

extension RegistrationRoleLabel on RegistrationRole {
  String get label => switch (this) {
    RegistrationRole.installer => 'Installer',
    RegistrationRole.retailer => 'Retailer',
  };
}

/// One buying source the applicant named. The name is looked up from the
/// number — the applicant never types a business name.
class BuyingSourceEntry {
  const BuyingSourceEntry({
    required this.mobileNumber,
    this.matchedName,
    this.matchedRole,
    this.matchedMarket,
  });

  final String mobileNumber;
  final String? matchedName;
  final String? matchedRole;
  final String? matchedMarket;

  bool get isFound => matchedName != null;

  String get summary => matchedName == null
      ? mobileNumber
      : '$matchedName · ${matchedRole ?? ''}'.trim();

  Map<String, Object?> toJson() => {
    'mobileNumber': mobileNumber,
    'matchedName': matchedName,
    'matchedRole': matchedRole,
    'matchedMarket': matchedMarket,
  };

  static BuyingSourceEntry fromJson(Map<String, Object?> json) =>
      BuyingSourceEntry(
        mobileNumber: json['mobileNumber']! as String,
        matchedName: json['matchedName'] as String?,
        matchedRole: json['matchedRole'] as String?,
        matchedMarket: json['matchedMarket'] as String?,
      );
}

/// Everything captured across the eight wizard steps, held in one place so a
/// partner can move back and forward — or leave the app entirely — without
/// losing what they entered.
class RegistrationDraft {
  const RegistrationDraft({
    this.countryCode = '+92',
    this.mobileNumber = '',
    this.role,
    this.fullName = '',
    this.alternateNumber = '',
    this.businessName = '',
    this.businessAddress = '',
    this.market,
    this.shopLatitude,
    this.shopLongitude,
    this.videoLinks = const ['', '', ''],
    this.shopImagePaths = const {},
    this.mobileVerified = false,
    this.buyingSources = const [],
    this.cnicNumber = '',
    this.cnicFrontPath,
    this.cnicBackPath,
    this.selfiePath,
    this.stepIndex = 0,
    this.updatedAt,
  });

  final String countryCode;
  final String mobileNumber;
  final RegistrationRole? role;

  final String fullName;
  final String alternateNumber;
  final String businessName;
  final String businessAddress;
  final String? market;

  /// Where the shop is, as pinned on the map. Deliberately separate from the
  /// phone's own location captured at first launch — the design supports
  /// them being different.
  final double? shopLatitude;
  final double? shopLongitude;

  /// Installer media: three links, the first two required.
  final List<String> videoLinks;

  /// Retailer media, keyed by the design's slot names ("Shop Board",
  /// "Shop Stock", "Shop Image") — values are local file paths.
  final Map<String, String> shopImagePaths;

  final bool mobileVerified;
  final List<BuyingSourceEntry> buyingSources;

  final String cnicNumber;
  final String? cnicFrontPath;
  final String? cnicBackPath;
  final String? selfiePath;

  /// The furthest step reached, so "Continue your registration?" can name it.
  final int stepIndex;
  final DateTime? updatedAt;

  String get fullMobileNumber => '$countryCode $mobileNumber'.trim();

  bool get hasShopPin => shopLatitude != null && shopLongitude != null;

  /// The source that receives the approval request; the rest are recorded
  /// with the application but are not asked to verify it.
  BuyingSourceEntry? get verifyingSource =>
      buyingSources.isEmpty ? null : buyingSources.first;

  RegistrationDraft copyWith({
    String? countryCode,
    String? mobileNumber,
    RegistrationRole? role,
    String? fullName,
    String? alternateNumber,
    String? businessName,
    String? businessAddress,
    String? market,
    double? shopLatitude,
    double? shopLongitude,
    List<String>? videoLinks,
    Map<String, String>? shopImagePaths,
    bool? mobileVerified,
    List<BuyingSourceEntry>? buyingSources,
    String? cnicNumber,
    String? cnicFrontPath,
    String? cnicBackPath,
    String? selfiePath,
    int? stepIndex,
    DateTime? updatedAt,
  }) {
    return RegistrationDraft(
      countryCode: countryCode ?? this.countryCode,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      alternateNumber: alternateNumber ?? this.alternateNumber,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      market: market ?? this.market,
      shopLatitude: shopLatitude ?? this.shopLatitude,
      shopLongitude: shopLongitude ?? this.shopLongitude,
      videoLinks: videoLinks ?? this.videoLinks,
      shopImagePaths: shopImagePaths ?? this.shopImagePaths,
      mobileVerified: mobileVerified ?? this.mobileVerified,
      buyingSources: buyingSources ?? this.buyingSources,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      cnicFrontPath: cnicFrontPath ?? this.cnicFrontPath,
      cnicBackPath: cnicBackPath ?? this.cnicBackPath,
      selfiePath: selfiePath ?? this.selfiePath,
      stepIndex: stepIndex ?? this.stepIndex,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'countryCode': countryCode,
    'mobileNumber': mobileNumber,
    'role': role?.name,
    'fullName': fullName,
    'alternateNumber': alternateNumber,
    'businessName': businessName,
    'businessAddress': businessAddress,
    'market': market,
    'shopLatitude': shopLatitude,
    'shopLongitude': shopLongitude,
    'videoLinks': videoLinks,
    'shopImagePaths': shopImagePaths,
    'mobileVerified': mobileVerified,
    'buyingSources': buyingSources.map((s) => s.toJson()).toList(),
    'cnicNumber': cnicNumber,
    'cnicFrontPath': cnicFrontPath,
    'cnicBackPath': cnicBackPath,
    'selfiePath': selfiePath,
    'stepIndex': stepIndex,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static RegistrationDraft fromJson(Map<String, Object?> json) {
    final roleName = json['role'] as String?;
    return RegistrationDraft(
      countryCode: json['countryCode'] as String? ?? '+92',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      role: roleName == null
          ? null
          : RegistrationRole.values.firstWhere((r) => r.name == roleName),
      fullName: json['fullName'] as String? ?? '',
      alternateNumber: json['alternateNumber'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? '',
      market: json['market'] as String?,
      shopLatitude: (json['shopLatitude'] as num?)?.toDouble(),
      shopLongitude: (json['shopLongitude'] as num?)?.toDouble(),
      videoLinks:
          (json['videoLinks'] as List?)?.map((e) => e as String).toList() ??
          const ['', '', ''],
      shopImagePaths:
          (json['shopImagePaths'] as Map?)?.map(
            (key, value) => MapEntry(key as String, value as String),
          ) ??
          const {},
      mobileVerified: json['mobileVerified'] as bool? ?? false,
      buyingSources:
          (json['buyingSources'] as List?)
              ?.map(
                (e) => BuyingSourceEntry.fromJson(e as Map<String, Object?>),
              )
              .toList() ??
          const [],
      cnicNumber: json['cnicNumber'] as String? ?? '',
      cnicFrontPath: json['cnicFrontPath'] as String?,
      cnicBackPath: json['cnicBackPath'] as String?,
      selfiePath: json['selfiePath'] as String?,
      stepIndex: json['stepIndex'] as int? ?? 0,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt']! as String),
    );
  }
}
