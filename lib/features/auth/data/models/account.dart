/// One of the four Crown Solar Energy partner user types (spec.md §Actors &
/// User Types). Authentication and device-binding rules are identical for
/// all four (FR-004, FR-022) — this enum exists for display/traceability
/// only, never for branching auth logic.
enum UserType { installer, retailer, wholesaler, distributor }

UserType userTypeFromWire(String value) => switch (value) {
  'installer' => UserType.installer,
  'retailer' => UserType.retailer,
  'wholesaler' => UserType.wholesaler,
  'distributor' => UserType.distributor,
  _ => throw ArgumentError('Unknown user type: $value'),
};

/// A Crown Solar Energy partner account (data-model.md `accounts`).
class Account {
  const Account({required this.id, required this.mobileNumber});

  final String id;
  final String mobileNumber;
}
