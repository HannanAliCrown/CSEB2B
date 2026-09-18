import 'dart:math';

/// Generates the simulated OTP code (research.md "OTP simulation surfaced
/// for prototype testability"). A 6-digit numeric string — not a stand-in
/// for any invented expiry/retry/lockout policy, just a value to compare
/// against on verification.
String generateOtpCode() {
  final random = Random.secure();
  final value = random.nextInt(900000) + 100000;
  return value.toString();
}
