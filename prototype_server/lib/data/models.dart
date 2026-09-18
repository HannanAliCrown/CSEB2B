/// Lightweight data-layer models for prototype_server, mirroring
/// specs/001-login-auth-device-binding/data-model.md field-for-field.
library;

class Account {
  const Account({
    required this.id,
    required this.mobileNumber,
    required this.userType,
  });

  final String id;
  final String mobileNumber;
  final String userType;
}

class Device {
  const Device({required this.id, required this.installationUuid});

  final String id;
  final String installationUuid;
}

enum BindingStatus { active, revoked }

enum BindingContext { initialRegistration, rebinding }

class AccountDeviceBinding {
  const AccountDeviceBinding({
    required this.id,
    required this.accountId,
    required this.deviceId,
    required this.status,
  });

  final String id;
  final String accountId;
  final String deviceId;
  final BindingStatus status;
}

enum OtpContext { registration, newDeviceLogin }

class OtpChallenge {
  const OtpChallenge({
    required this.id,
    required this.accountId,
    required this.deviceId,
    required this.context,
    required this.code,
    required this.verified,
  });

  final String id;
  final String accountId;
  final String deviceId;
  final OtpContext context;
  final String code;
  final bool verified;
}

enum RebindingAuthorizationStatus { pending, authorized, notAuthorized }

class RebindingAuthorization {
  const RebindingAuthorization({
    required this.id,
    required this.accountId,
    required this.deviceId,
    required this.status,
  });

  final String id;
  final String accountId;
  final String deviceId;
  final RebindingAuthorizationStatus status;
}

/// The three device-binding states the system recognizes (FR-008).
/// `newUntrusted` is never a stored row — it is the absence of an active
/// binding for the (account, device) pair.
enum DeviceBindingStatus { active, revoked, newUntrusted }

/// An account's device-move tier (spec.md "Device-Move Tiers"):
/// [secondDevice] if the account has completed zero prior
/// `rebinding`-context moves since its registration (Device 1) binding —
/// gated by login-context OTP alone, no authorization check at all;
/// [thirdOrLater] if it has completed one or more — gated by a
/// rebinding-authorization outcome of `authorized` *before* any OTP is
/// requested. Always derived fresh from `account_device_bindings` history
/// (data-model.md); never a stored column, never computed client-side
/// (FR-015, FR-046).
enum DeviceMoveTier { secondDevice, thirdOrLater }

String rebindingAuthorizationStatusToJson(
  RebindingAuthorizationStatus status,
) => switch (status) {
  RebindingAuthorizationStatus.pending => 'pending',
  RebindingAuthorizationStatus.authorized => 'authorized',
  RebindingAuthorizationStatus.notAuthorized => 'not_authorized',
};

String deviceMoveTierToJson(DeviceMoveTier tier) => switch (tier) {
  DeviceMoveTier.secondDevice => 'second_device',
  DeviceMoveTier.thirdOrLater => 'third_or_later',
};
