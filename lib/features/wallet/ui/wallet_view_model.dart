// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../session/data/signed_in_user.dart';
import '../data/wallet_repository.dart';

/// Where the Send Cash flow is.
enum SendCashStep { recipient, amount, review, sent }

/// Drives the wallet screens: the ledger, and the four steps of sending cash.
/// Every amount, name and balance here comes from [WalletRepository].
class WalletViewModel extends ChangeNotifier {
  WalletViewModel({
    required WalletRepository repository,
    required SignedInUser user,
  }) : _repository = repository,
       _user = user;

  final WalletRepository _repository;
  final SignedInUser _user;

  SignedInUser get user => _user;

  bool busy = false;
  String? error;

  Money balance = const Money(0);
  List<LedgerEntry> entries = const [];
  List<CashRecipient> recipients = const [];

  // --- Send Cash ---
  SendCashStep step = SendCashStep.recipient;
  CashRecipient? recipient;
  String amountText = '';
  String note = '';
  TransferResult? result;

  Money get amount => Money.rupees(int.tryParse(amountText.trim()) ?? 0);

  Future<void> load() async {
    busy = true;
    notifyListeners();

    balance = await _repository.balance(_user);
    entries = await _repository.ledger(_user);
    recipients = await _repository.recentRecipients(_user);

    busy = false;
    notifyListeners();
  }

  /// Picks someone already in the directory.
  void chooseRecipient(CashRecipient value) {
    recipient = value;
    error = null;
    step = SendCashStep.amount;
    notifyListeners();
  }

  /// Resolves a typed number, so a name is never typed by hand.
  Future<void> lookupRecipient(String mobileNumber) async {
    busy = true;
    error = null;
    notifyListeners();

    final found = await _repository.lookupRecipient(mobileNumber);
    busy = false;

    if (found == null) {
      error = 'No Crown Solar account found for this number.';
      notifyListeners();
      return;
    }
    chooseRecipient(found);
  }

  void setAmount(String value) {
    amountText = value;
    error = null;
    notifyListeners();
  }

  void setNote(String value) {
    note = value;
    notifyListeners();
  }

  /// The reason the amount cannot be sent yet, or null when it can.
  String? get amountProblem {
    if (amountText.trim().isEmpty) return null;
    if (amount.compareTo(MockWalletRepository.minimumTransfer) < 0) {
      return 'The smallest transfer is '
          'PKR ${MockWalletRepository.minimumTransfer.formatted}.';
    }
    if (amount.compareTo(balance) > 0) {
      return 'That is more than your balance of PKR ${balance.formatted}.';
    }
    return null;
  }

  bool get canReview =>
      recipient != null && !amount.isZero && amountProblem == null;

  void review() {
    if (!canReview) return;
    step = SendCashStep.review;
    notifyListeners();
  }

  void back() {
    step = switch (step) {
      SendCashStep.amount => SendCashStep.recipient,
      SendCashStep.review => SendCashStep.amount,
      SendCashStep.recipient || SendCashStep.sent => step,
    };
    error = null;
    notifyListeners();
  }

  Future<void> send() async {
    final target = recipient;
    if (target == null || !canReview) return;

    busy = true;
    error = null;
    notifyListeners();

    final outcome = await _repository.sendCash(
      from: _user,
      toMobileNumber: target.mobileNumber,
      amount: amount,
      note: note,
    );

    busy = false;

    if (!outcome.succeeded) {
      error = switch (outcome.failure!) {
        TransferFailure.unknownRecipient =>
          'That number no longer has a Crown Solar account.',
        TransferFailure.notEnoughBalance =>
          'Your balance has changed and no longer covers this.',
        TransferFailure.amountTooSmall =>
          'The smallest transfer is '
              'PKR ${MockWalletRepository.minimumTransfer.formatted}.',
        TransferFailure.self => 'You cannot send cash to yourself.',
      };
      step = SendCashStep.amount;
      notifyListeners();
      return;
    }

    result = outcome;
    step = SendCashStep.sent;
    await load();
  }

  /// Starts a second transfer without leaving the screen.
  void reset() {
    step = SendCashStep.recipient;
    recipient = null;
    amountText = '';
    note = '';
    result = null;
    error = null;
    notifyListeners();
  }
}
