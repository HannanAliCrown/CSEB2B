/// The prototype's local, on-device representation of an authenticated
/// session (data-model.md `Session` — local-only, never a PostgreSQL
/// table). Tracked separately from device-binding state; restoring it
/// always re-validates against the current device-binding state via
/// [AuthRepository.restoreSession] rather than trusting this record alone
/// (FR-030).
class Session {
  const Session({
    required this.accountId,
    required this.deviceInstallationUuid,
    required this.keepSignedIn,
    required this.createdAt,
  });

  final String accountId;
  final String deviceInstallationUuid;
  final bool keepSignedIn;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'accountId': accountId,
    'deviceInstallationUuid': deviceInstallationUuid,
    'keepSignedIn': keepSignedIn,
    'createdAt': createdAt.toIso8601String(),
  };

  static Session fromJson(Map<String, Object?> json) => Session(
    accountId: json['accountId'] as String,
    deviceInstallationUuid: json['deviceInstallationUuid'] as String,
    keepSignedIn: json['keepSignedIn'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
