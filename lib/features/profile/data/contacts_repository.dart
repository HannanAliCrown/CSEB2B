// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/mock/partner_directory.dart';
import '../../../core/prefs/app_preferences.dart';

/// A phone contact that turned out to be a Crown Solar partner.
class SyncedContact {
  const SyncedContact({
    required this.mobileNumber,
    required this.businessName,
    required this.role,
    required this.phoneName,
  });

  final String mobileNumber;
  final String businessName;
  final String role;

  /// What the partner is saved as in the phone's own address book.
  final String phoneName;

  Map<String, dynamic> toJson() => {
    'mobileNumber': mobileNumber,
    'businessName': businessName,
    'role': role,
    'phoneName': phoneName,
  };

  static SyncedContact fromJson(Map<String, dynamic> json) => SyncedContact(
    mobileNumber: json['mobileNumber'] as String? ?? '',
    businessName: json['businessName'] as String? ?? '',
    role: json['role'] as String? ?? '',
    phoneName: json['phoneName'] as String? ?? '',
  );
}

/// What a sync attempt produced.
enum SyncOutcome { synced, permissionRefused, failed }

class SyncResult {
  const SyncResult({
    required this.outcome,
    this.matched = const [],
    this.scanned = 0,
  });

  final SyncOutcome outcome;
  final List<SyncedContact> matched;

  /// How many contacts were read, so the screen can say what was discarded.
  final int scanned;

  int get discarded => scanned - matched.length;
}

/// The address book, matched against Crown Solar's partner records.
///
/// Only numbers that already belong to a partner are kept. Everything else is
/// read, compared in memory and thrown away — it is never stored and never
/// leaves the phone.
abstract interface class ContactsRepository {
  Future<List<SyncedContact>> saved();
  Future<DateTime?> lastSyncedAt();
  Future<SyncResult> sync();
  Future<void> forget();
}

class DeviceContactsRepository implements ContactsRepository {
  DeviceContactsRepository({required AppPreferences preferences})
    : _preferences = preferences;

  final AppPreferences _preferences;

  static const _contactsKey = 'contacts.synced';
  static const _syncedAtKey = 'contacts.synced_at';

  @override
  Future<List<SyncedContact>> saved() async {
    final raw = await _preferences.readString(_contactsKey);
    if (raw == null) return const [];
    try {
      return [
        for (final entry in jsonDecode(raw) as List<dynamic>)
          SyncedContact.fromJson(entry as Map<String, dynamic>),
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<DateTime?> lastSyncedAt() async {
    final raw = await _preferences.readString(_syncedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<SyncResult> sync() async {
    // Read-only: the app never writes to the address book.
    final permission = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    if (permission != PermissionStatus.granted) {
      return const SyncResult(outcome: SyncOutcome.permissionRefused);
    }

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );

      final matched = <String, SyncedContact>{};
      var scanned = 0;

      for (final contact in contacts) {
        for (final phone in contact.phones) {
          scanned++;
          final account = PartnerDirectory.find(phone.number);
          if (account == null) continue;
          // Keyed by number so one partner saved twice does not double up.
          matched[PartnerDirectory.normalise(
            account.mobileNumber,
          )] = SyncedContact(
            mobileNumber: account.mobileNumber,
            businessName: account.displayName,
            role: account.role,
            phoneName: contact.displayName ?? account.contactName,
          );
        }
      }

      final kept = matched.values.toList()
        ..sort((a, b) => a.businessName.compareTo(b.businessName));

      await _preferences.writeString(
        _contactsKey,
        jsonEncode([for (final contact in kept) contact.toJson()]),
      );
      await _preferences.writeString(
        _syncedAtKey,
        DateTime.now().toIso8601String(),
      );

      return SyncResult(
        outcome: SyncOutcome.synced,
        matched: kept,
        scanned: scanned,
      );
    } on Object {
      return const SyncResult(outcome: SyncOutcome.failed);
    }
  }

  @override
  Future<void> forget() async {
    await _preferences.removeKey(_contactsKey);
    await _preferences.removeKey(_syncedAtKey);
  }
}
