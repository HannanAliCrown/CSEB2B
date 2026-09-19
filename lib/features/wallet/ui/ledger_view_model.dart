// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../session/data/signed_in_user.dart';
import '../data/wallet_repository.dart';

/// Which side of the ledger to show.
enum LedgerDirectionFilter { all, credits, debits }

/// How far back to look.
enum LedgerRange { thisMonth, lastSixty, everything, custom }

extension LedgerRangeX on LedgerRange {
  String get label => switch (this) {
    LedgerRange.thisMonth => 'This month',
    LedgerRange.lastSixty => 'Last 60 days',
    LedgerRange.everything => 'Everything',
    LedgerRange.custom => 'Custom range',
  };
}

/// One line with the balance it left behind.
class LedgerRow {
  const LedgerRow({required this.entry, required this.balanceAfter});

  final LedgerEntry entry;

  /// The running balance once this line had posted. Null for a held line —
  /// nothing has settled yet, so there is no balance to show.
  final Money? balanceAfter;
}

/// Where an export got to.
enum ExportStage { idle, generating, ready, failed }

/// Drives the ledger: the three totals, the filters, the day groups and the
/// export. Every figure is derived from the repository's entries, so the
/// header and the rows can never disagree.
class LedgerViewModel extends ChangeNotifier {
  LedgerViewModel({
    required WalletRepository repository,
    required SignedInUser user,
  }) : _repository = repository,
       _user = user;

  final WalletRepository _repository;
  final SignedInUser _user;

  SignedInUser get user => _user;

  bool busy = false;
  List<LedgerEntry> _all = const [];

  // --- Totals ---
  Money available = const Money(0);
  Money held = const Money(0);

  /// Everything the partner owns, spendable or not.
  Money get balance => available + held;

  // --- Filters ---
  LedgerRange range = LedgerRange.thisMonth;
  LedgerDirectionFilter direction = LedgerDirectionFilter.all;
  final Set<LedgerType> types = {};

  /// The two ends of [LedgerRange.custom], inclusive. Both are whole days:
  /// a statement is asked for by date, not by the minute.
  DateTime? customFrom;
  DateTime? customTo;

  /// The chip's text: the named ranges say their name, a custom one says its
  /// dates, because "Custom range" on its own tells the partner nothing.
  String get rangeLabel {
    if (range != LedgerRange.custom) return range.label;
    final from = customFrom;
    final to = customTo;
    if (from == null || to == null) return range.label;
    return '${_shortDay(from)} – ${_shortDay(to)}';
  }

  bool get isFiltered =>
      range != LedgerRange.thisMonth ||
      direction != LedgerDirectionFilter.all ||
      types.isNotEmpty;

  /// True when there is nothing at all, filters aside.
  bool get isEmpty => _all.isEmpty;

  // --- Export ---
  ExportStage exportStage = ExportStage.idle;
  File? exportFile;
  int exportBytes = 0;
  String? exportError;

  Future<void> load() async {
    busy = true;
    notifyListeners();

    available = await _repository.balance(_user);
    held = await _repository.heldTotal(_user);
    _all = await _repository.ledger(_user);

    busy = false;
    notifyListeners();
  }

  void setRange(LedgerRange value) {
    range = value;
    notifyListeners();
  }

  /// Picks the two dates and switches to them in one step, so the filter can
  /// never sit on [LedgerRange.custom] with nothing chosen.
  ///
  /// The dates are normalised to whole days and swapped if they arrive the
  /// wrong way round.
  void setCustomRange(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final swap = end.isBefore(start);

    customFrom = swap ? end : start;
    customTo = swap ? start : end;
    range = LedgerRange.custom;
    notifyListeners();
  }

  void setDirection(LedgerDirectionFilter value) {
    direction = value;
    notifyListeners();
  }

  void toggleType(LedgerType type) {
    types.contains(type) ? types.remove(type) : types.add(type);
    notifyListeners();
  }

  void resetFilters() {
    range = LedgerRange.thisMonth;
    direction = LedgerDirectionFilter.all;
    types.clear();
    customFrom = null;
    customTo = null;
    notifyListeners();
  }

  bool _inRange(LedgerEntry entry) {
    final now = DateTime.now();
    return switch (range) {
      LedgerRange.everything => true,
      LedgerRange.lastSixty => entry.postedAt.isAfter(
        now.subtract(const Duration(days: 60)),
      ),
      LedgerRange.thisMonth =>
        entry.postedAt.year == now.year && entry.postedAt.month == now.month,
      // Both ends are inclusive whole days: an entry posted at any time on
      // the closing date belongs in the statement.
      LedgerRange.custom => _inCustomRange(entry.postedAt),
    };
  }

  bool _inCustomRange(DateTime when) {
    final from = customFrom;
    final to = customTo;
    if (from != null && when.isBefore(from)) return false;
    if (to != null && !when.isBefore(to.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  bool _matchesDirection(LedgerEntry entry) => switch (direction) {
    LedgerDirectionFilter.all => true,
    LedgerDirectionFilter.credits => entry.isCredit,
    LedgerDirectionFilter.debits => !entry.isCredit,
  };

  /// The visible lines, newest first, each carrying the balance it left.
  ///
  /// The running balance is worked out over the whole history, not the
  /// filtered view — a filtered row still shows the real balance at the time.
  List<LedgerRow> get rows {
    final oldestFirst = [..._all]
      ..sort((a, b) => a.postedAt.compareTo(b.postedAt));

    final balances = <String, Money?>{};
    var running = const Money(0);
    for (final entry in oldestFirst) {
      if (entry.state == LedgerState.held) {
        // Held money has left the available balance but settled nowhere.
        running = running - entry.amount;
        balances[entry.id] = null;
        continue;
      }
      if (entry.state == LedgerState.rejected) {
        balances[entry.id] = running;
        continue;
      }
      running = entry.isCredit
          ? running + entry.amount
          : running - entry.amount;
      balances[entry.id] = running;
    }

    return [
      for (final entry in _all)
        if (_inRange(entry) &&
            _matchesDirection(entry) &&
            (types.isEmpty || types.contains(entry.type)))
          LedgerRow(entry: entry, balanceAfter: balances[entry.id]),
    ];
  }

  /// The visible lines split into Today and Earlier, as the design groups
  /// them. Empty groups are dropped rather than shown as a bare heading.
  List<({String label, List<LedgerRow> rows})> get groups {
    final now = DateTime.now();
    bool isToday(DateTime when) =>
        when.year == now.year && when.month == now.month && when.day == now.day;

    final today = rows.where((r) => isToday(r.entry.postedAt)).toList();
    final earlier = rows.where((r) => !isToday(r.entry.postedAt)).toList();

    return [
      if (today.isNotEmpty) (label: 'Today', rows: today),
      if (earlier.isNotEmpty) (label: 'Earlier', rows: earlier),
    ];
  }

  /// Writes the visible lines to a CSV the partner can keep or share.
  ///
  /// A spreadsheet, not a PDF: this prototype has no PDF engine, and a file
  /// that really opens is worth more than one that pretends to.
  Future<void> exportLedger() async {
    exportStage = ExportStage.generating;
    exportError = null;
    notifyListeners();

    try {
      final buffer = StringBuffer(
        'Date,Reference,Description,Type,Direction,Amount,State\n',
      );
      for (final row in rows) {
        final e = row.entry;
        buffer.writeln(
          [
            e.postedAt.toIso8601String(),
            e.id,
            '"${e.title.replaceAll('"', "'")}"',
            e.type.label,
            e.isCredit ? 'Credit' : 'Debit',
            (e.amount.paisa / 100).toStringAsFixed(2),
            e.state.name,
          ].join(','),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now();
      final name =
          'Ledger_${stamp.year}-'
          '${stamp.month.toString().padLeft(2, '0')}-'
          '${stamp.day.toString().padLeft(2, '0')}.csv';

      final file = File('${directory.path}/$name');
      await file.writeAsString(buffer.toString());

      exportFile = file;
      exportBytes = await file.length();
      exportStage = ExportStage.ready;
    } on Object catch (error) {
      exportError = '$error';
      exportStage = ExportStage.failed;
    }
    notifyListeners();
  }

  /// "5 Sep" — the date without the year, which the chip has no room for.
  static String _shortDay(DateTime when) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${when.day} ${months[when.month - 1]}';
  }

  void dismissExport() {
    exportStage = ExportStage.idle;
    exportFile = null;
    exportError = null;
    notifyListeners();
  }
}
