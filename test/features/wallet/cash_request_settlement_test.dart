import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/mock/partner_directory.dart';
import 'package:cse_b2b/core/mock/pending_registrations.dart';
import 'package:cse_b2b/features/session/data/signed_in_user.dart';
import 'package:cse_b2b/features/wallet/data/cash_requests_service.dart';
import 'package:cse_b2b/features/wallet/data/wallet_repository.dart';

final _sender = SignedInUser.fromAccount(PartnerDirectory.find('3004821190')!);
final _receiver = SignedInUser.fromAccount(
  PartnerDirectory.find('3007781204')!,
);

final _amount = Money.rupees(2000);

/// Both partners are seeded with an opening history, one held line included,
/// so every expectation here is about what a transfer *changed* rather than
/// what a total happens to be.
typedef _Totals = ({Money senderBalance, Money senderHeld, Money receiver});

void main() {
  group('cash request settlement', () {
    late MockWalletRepository wallet;
    late MockCashRequestsService requests;

    setUp(() {
      wallet = MockWalletRepository();
      requests = MockCashRequestsService(wallet: wallet);
    });

    Future<_Totals> totals() async => (
      senderBalance: await wallet.balance(_sender),
      senderHeld: await wallet.heldTotal(_sender),
      receiver: await wallet.balance(_receiver),
    );

    Future<String> send() async {
      final result = await wallet.sendCash(
        from: _sender,
        toMobileNumber: _receiver.mobileNumber,
        amount: _amount,
      );
      expect(result.succeeded, isTrue);
      expect(result.held, isTrue);
      return result.entry!.id;
    }

    test(
      'a transfer reaches the inbox of the partner it was sent to',
      () async {
        final reference = await send();

        final inbox = await requests.requests(_receiver.mobileNumber);
        final request = inbox!.firstWhere((r) => r.reference == reference);

        expect(request.waiting, isTrue);
        expect(request.amount, _amount);
        expect(
          request.fromName,
          PartnerDirectory.find('3004821190')!.displayName,
        );
      },
    );

    test('sending holds the amount without crediting anyone', () async {
      final before = await totals();
      await send();
      final after = await totals();

      // Out of the spendable balance and into the hold the moment it is sent.
      expect(after.senderBalance, before.senderBalance - _amount);
      expect(after.senderHeld, before.senderHeld + _amount);
      expect(after.receiver, before.receiver);
    });

    test(
      "approving credits the receiver and releases the sender's hold",
      () async {
        final before = await totals();
        final reference = await send();

        expect(
          await requests.decide(
            mobileNumber: _receiver.mobileNumber,
            reference: reference,
            approved: true,
          ),
          isTrue,
        );

        final after = await totals();
        expect(after.senderBalance, before.senderBalance - _amount);
        expect(after.senderHeld, before.senderHeld);
        expect(after.receiver, before.receiver + _amount);
      },
    );

    test(
      'rejecting returns the amount to the sender and credits nobody',
      () async {
        final before = await totals();
        final reference = await send();

        expect(
          await requests.decide(
            mobileNumber: _receiver.mobileNumber,
            reference: reference,
            approved: false,
          ),
          isTrue,
        );

        final after = await totals();
        expect(after.senderBalance, before.senderBalance);
        expect(after.senderHeld, before.senderHeld);
        expect(after.receiver, before.receiver);
      },
    );

    test('a partner who registered on this phone can be paid', () async {
      // Approved on all three, so they can open the app and answer.
      final fresh = PendingRegistration(
        reference: 'CSE-PR-TEST',
        mobileNumber: '+92 311 2223344',
        businessName: 'Fresh Solar Store',
        contactName: 'New Partner',
        role: 'Retailer',
        market: 'Hall Road, Lahore',
        verifyingSourceName: null,
        submittedAt: DateTime.now(),
      );
      for (final approver in Approver.values) {
        fresh.approvals[approver] = ApprovalState.approved;
      }
      PendingRegistrations.add(fresh);
      addTearDown(PendingRegistrations.clear);

      // They are not in the bundled directory, so nothing may assume that
      // being absent from it means being nobody.
      expect(PartnerDirectory.find(fresh.mobileNumber), isNull);
      expect(await wallet.lookupRecipient(fresh.mobileNumber), isNotNull);

      final sent = await wallet.sendCash(
        from: _sender,
        toMobileNumber: fresh.mobileNumber,
        amount: _amount,
      );
      expect(sent.succeeded, isTrue);

      final inbox = await requests.requests(fresh.mobileNumber);
      final request = inbox!.firstWhere((r) => r.reference == sent.entry!.id);
      expect(request.waiting, isTrue);
      expect(
        request.fromName,
        PartnerDirectory.find('3004821190')!.displayName,
      );

      final freshUser = SignedInUser.fromPending(fresh);
      expect(await wallet.balance(freshUser), Money.rupees(0));

      expect(
        await requests.decide(
          mobileNumber: fresh.mobileNumber,
          reference: sent.entry!.id,
          approved: true,
        ),
        isTrue,
      );
      expect(await wallet.balance(freshUser), _amount);
    });

    test('an application still waiting cannot be paid', () async {
      final waiting = PendingRegistration(
        reference: 'CSE-PR-TEST-2',
        mobileNumber: '+92 313 4445566',
        businessName: 'Not Approved Yet',
        contactName: 'Applicant',
        role: 'Retailer',
        market: 'Hall Road, Lahore',
        verifyingSourceName: null,
        submittedAt: DateTime.now(),
      );
      PendingRegistrations.add(waiting);
      addTearDown(PendingRegistrations.clear);

      // They cannot open the app to answer a transfer, so nothing is sent.
      expect(await wallet.lookupRecipient(waiting.mobileNumber), isNull);
      final sent = await wallet.sendCash(
        from: _sender,
        toMobileNumber: waiting.mobileNumber,
        amount: _amount,
      );
      expect(sent.succeeded, isFalse);
      expect(sent.failure, TransferFailure.unknownRecipient);
    });

    test('a transfer can only be decided once', () async {
      final reference = await send();

      expect(
        await requests.decide(
          mobileNumber: _receiver.mobileNumber,
          reference: reference,
          approved: false,
        ),
        isTrue,
      );
      expect(
        await requests.decide(
          mobileNumber: _receiver.mobileNumber,
          reference: reference,
          approved: true,
        ),
        isFalse,
      );
    });
  });
}
