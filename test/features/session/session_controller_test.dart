import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/mock/pending_registrations.dart';
import 'package:cse_b2b/core/prefs/app_preferences.dart';
import 'package:cse_b2b/features/session/data/session_repository.dart';
import 'package:cse_b2b/features/session/data/signed_in_user.dart';
import 'package:cse_b2b/features/session/ui/session_controller.dart';

SessionController _build(InMemoryAppPreferences prefs) =>
    SessionController(repository: SessionRepository(preferences: prefs));

void main() {
  group('sign in', () {
    test('a registered number signs in as that partner', () async {
      final session = _build(InMemoryAppPreferences());

      final ok = await session.signIn('3004821190', keepSignedIn: true);

      expect(ok, isTrue);
      expect(session.user?.businessName, 'Adnan Solar Works');
      expect(session.user?.role, PartnerRole.installer);
      expect(session.user?.contactName, 'Muhammad Adnan Shahid');
    });

    test('the leading 0 and +92 forms reach the same account', () async {
      for (final typed in ['03004821190', '+92 300 4821190', '300 4821190']) {
        final session = _build(InMemoryAppPreferences());
        await session.signIn(typed, keepSignedIn: false);
        expect(
          session.user?.businessName,
          'Adnan Solar Works',
          reason: 'typed as $typed',
        );
      }
    });

    test('an unregistered number is refused', () async {
      final session = _build(InMemoryAppPreferences());

      final ok = await session.signIn('3009990000', keepSignedIn: true);

      expect(ok, isFalse);
      expect(session.user, isNull);
      expect(session.failure, SignInFailure.unknownNumber);
    });

    test('a short number never reaches the directory', () async {
      final session = _build(InMemoryAppPreferences());

      await session.signIn('30048', keepSignedIn: true);

      expect(session.failure, SignInFailure.malformedNumber);
    });

    test('Keep me signed in survives a restart', () async {
      final prefs = InMemoryAppPreferences();
      await _build(prefs).signIn('3004821190', keepSignedIn: true);

      final next = _build(prefs);
      await next.restore();

      expect(next.isSignedIn, isTrue);
      expect(next.user?.businessName, 'Adnan Solar Works');
    });

    test('leaving it unchecked does not', () async {
      final prefs = InMemoryAppPreferences();
      await _build(prefs).signIn('3004821190', keepSignedIn: false);

      final next = _build(prefs);
      await next.restore();

      expect(next.isSignedIn, isFalse);
    });

    test('a submitted application signs in unapproved', () async {
      addTearDown(PendingRegistrations.clear);
      PendingRegistrations.add(
        PendingRegistration(
          reference: 'CSE-PR-2026-000001',
          mobileNumber: '+92 300 5550001',
          businessName: 'New Solar Works',
          contactName: 'Applicant',
          role: 'Installer',
          market: 'Ravi Road, Lahore',
          verifyingSourceName: 'Al-Noor Electric Store',
          submittedAt: DateTime(2026, 9, 19),
        ),
      );
      final session = _build(InMemoryAppPreferences());

      final ok = await session.signIn('3005550001', keepSignedIn: true);

      expect(ok, isTrue);
      expect(session.user?.businessName, 'New Solar Works');
      expect(
        session.user?.approved,
        isFalse,
        reason: 'nothing opens until the three approvals are in',
      );
    });

    test('all three approvals open the account', () async {
      addTearDown(PendingRegistrations.clear);
      final pending = PendingRegistration(
        reference: 'CSE-PR-2026-000002',
        mobileNumber: '+92 300 4821190',
        businessName: 'Adnan Solar Works',
        contactName: 'Muhammad Adnan Shahid',
        role: 'Installer',
        market: 'Ravi Road, Lahore',
        verifyingSourceName: 'Al-Noor Electric Store',
        submittedAt: DateTime(2026, 9, 19),
      );
      PendingRegistrations.add(pending);

      expect(pending.isApproved, isFalse);
      for (final approver in Approver.values) {
        pending.approvals[approver] = ApprovalState.approved;
      }
      expect(pending.isApproved, isTrue);

      final session = _build(InMemoryAppPreferences());
      await session.signIn('3004821190', keepSignedIn: false);

      expect(session.user?.approved, isTrue);
    });

    test('signing out clears the saved session', () async {
      final prefs = InMemoryAppPreferences();
      final session = _build(prefs);
      await session.signIn('3004821190', keepSignedIn: true);

      await session.signOut();

      expect(session.isSignedIn, isFalse);
      final next = _build(prefs);
      await next.restore();
      expect(next.isSignedIn, isFalse);
    });
  });
}
