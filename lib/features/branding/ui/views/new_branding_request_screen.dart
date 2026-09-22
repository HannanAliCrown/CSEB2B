import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../registration/data/services/media_capture_service.dart';
import '../../../wallet/data/wallet_repository.dart' show Money;
import '../../../session/ui/session_controller.dart';
import '../../data/branding_service.dart';
import 'branding_screens.dart' show ExpenseShareCard;

/// Board 07 · A2 and A3 — the request wizard: shop details, then a type for
/// every board asked for.
///
/// Both steps live in one screen because step 2 is sized by step 1: the
/// number of boards decides how many types are picked.
class NewBrandingRequestScreen extends StatefulWidget {
  const NewBrandingRequestScreen({super.key, required this.onOpenScanner});

  final VoidCallback onOpenScanner;

  @override
  State<NewBrandingRequestScreen> createState() =>
      _NewBrandingRequestScreenState();
}

class _NewBrandingRequestScreenState extends State<NewBrandingRequestScreen> {
  final _height = TextEditingController();
  final _width = TextEditingController();
  final _count = TextEditingController(text: '1');
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _person = TextEditingController();

  String? _shopPhoto;
  String? _cardPhoto;

  /// 1 = shop details, 2 = board type.
  int _step = 1;

  BrandingOptions? _options;
  bool _loadingOptions = false;

  /// One chosen code per board, indexed by position.
  final List<String?> _picked = [];

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final field in [_height, _width, _count]) {
      field.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final field in [
      _height,
      _width,
      _count,
      _address,
      _contact,
      _person,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  int get _boards => int.tryParse(_count.text.trim()) ?? 0;

  /// Both photos and all three measurements, as the board requires before
  /// Continue is offered at all.
  bool get _detailsComplete =>
      _shopPhoto != null &&
      _cardPhoto != null &&
      (double.tryParse(_height.text.trim()) ?? 0) > 0 &&
      (double.tryParse(_width.text.trim()) ?? 0) > 0 &&
      _boards > 0;

  @override
  Widget build(BuildContext context) =>
      _step == 1 ? _detailsStep() : _boardTypeStep();

  // --- A2 · Step 1 ----------------------------------------------------------

  Widget _detailsStep() {
    return DsScreen(
      appBar: DsAppBar(
        title: 'New Request',
        subtitle: 'Step 1 of 3 · Shop details',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 14,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Choose Board Type',
          iconAfter: LucideIcons.arrowRight,
          loading: _loadingOptions,
          // Stays disabled until both photos and all three measurements
          // exist, so the step is never half-sent.
          disabled: !_detailsComplete || _loadingOptions,
          onPressed: _openBoardTypes,
        ),
      ),
      sections: [
        DsUploadRow(
          label: 'Shop picture',
          state: _shopPhoto == null
              ? DsUploadState.empty
              : DsUploadState.uploaded,
          meta: _shopPhoto == null ? 'Required' : 'Added',
          icon: LucideIcons.camera,
          onAction: () => _capture(shop: true),
        ),
        DsUploadRow(
          label: 'Visiting card',
          state: _cardPhoto == null
              ? DsUploadState.empty
              : DsUploadState.uploaded,
          meta: _cardPhoto == null ? 'Required' : 'Added',
          icon: LucideIcons.idCard,
          onAction: () => _capture(shop: false),
        ),
        Row(
          children: [
            Expanded(
              child: DsInput(
                label: 'Board height',
                unit: 'ft',
                controller: _height,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DsInput(
                label: 'Board width',
                unit: 'ft',
                controller: _width,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
          ],
        ),
        DsInput(
          label: 'Number of boards',
          controller: _count,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        Text(
          'OPTIONAL',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        DsInput(
          label: 'Shop address',
          placeholder: 'If different from your profile',
          controller: _address,
        ),
        DsInput(
          label: 'Contact number',
          placeholder: 'Optional',
          controller: _contact,
          keyboardType: TextInputType.phone,
        ),
        DsInput(
          label: "Person's name",
          placeholder: 'Optional',
          controller: _person,
        ),
      ],
    );
  }

  Future<void> _capture({required bool shop}) async {
    final picked = await context.read<MediaCaptureService>().pickShopImage(
      MediaSource.camera,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (shop) {
        _shopPhoto = picked;
      } else {
        _cardPhoto = picked;
      }
    });
  }

  Future<void> _openBoardTypes() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _loadingOptions = true);
    final options = await context.read<BrandingService>().boardTypes(
      user.mobileNumber,
    );
    if (!mounted) return;

    if (options == null) {
      setState(() => _loadingOptions = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(BrandingFailure.unreachable.message)),
      );
      return;
    }

    setState(() {
      _loadingOptions = false;
      _options = options;
      _picked
        ..clear()
        // With one option and nothing to weigh, it is already the answer —
        // the replacement and installer paths both land here.
        ..addAll(
          List.filled(
            _boards,
            options.open.length == 1 ? options.open.single.code : null,
          ),
        );
      _step = 2;
    });
  }

  // --- A3 · A4 · A5 · Step 2 ------------------------------------------------

  Widget _boardTypeStep() {
    final options = _options!;
    final eligibility = options.eligibility;
    final ready = _picked.every((code) => code != null);

    return DsScreen(
      appBar: DsAppBar(
        title: 'Board Type',
        subtitle: 'Step 2 of 3 · ${_boardsLabel()}',
        onBack: () => setState(() => _step = 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      footer: options.hasAnyOpen
          ? DsFooterBar(
              child: DsButton(
                label: 'Submit Request',
                iconAfter: LucideIcons.arrowRight,
                loading: _busy,
                disabled: !ready || _busy,
                onPressed: _submit,
              ),
            )
          : null,
      sections: [
        // Board 07 · A5 — replacement detection overrides everything, so it
        // is said before the single option it leaves.
        if (options.replacementOnly && eligibility.existingBoardName != null)
          DsNotice(
            icon: LucideIcons.info,
            tone: DsTone.info,
            title: 'You already have a ${eligibility.existingBoardName}',
            message: options.replacementNotice ?? '',
          )
        else if (options.hasAnyOpen)
          DsBody(_availabilityLine(eligibility), size: 14),

        if (!options.hasAnyOpen)
          ..._noOptions(options)
        else ...[
          for (var i = 0; i < _picked.length; i++)
            _BoardSlot(
              index: i,
              total: _picked.length,
              options: options,
              selected: _picked[i],
              onChange: () => _pick(i),
            ),

          if (_pickedTypes.isNotEmpty) _shareCard(),

          if (options.boardTypes.any((type) => !type.available))
            const DsCaption(
              'Locked options state their own condition when you tap Change.',
            ),
        ],
      ],
    );
  }

  String _boardsLabel() =>
      '${_picked.length} ${_picked.length == 1 ? 'board' : 'boards'} requested';

  /// "Available to you as a Retailer with a signed scheme and 182,400
  /// points." — the same sentence the board writes, from real figures.
  String _availabilityLine(BrandingEligibility eligibility) {
    final role =
        eligibility.role[0].toUpperCase() + eligibility.role.substring(1);
    final clauses = [
      if (eligibility.schemeSigned) 'a signed scheme',
      '${eligibility.pointsFormatted} points',
    ];
    return 'Available to you as a $role with ${clauses.join(' and ')}. '
        'Each board below can be a different type.';
  }

  List<BrandingBoardType> get _pickedTypes => [
    for (final code in _picked)
      if (code != null)
        _options!.boardTypes.firstWhere((type) => type.code == code),
  ];

  Widget _shareCard() {
    final types = _pickedTypes;
    final company = types.fold(0, (sum, t) => sum + t.companyShare.paisa);
    final partner = types.fold(0, (sum, t) => sum + t.partnerShare.paisa);
    final total = company + partner;
    final many = _picked.length > 1;

    return ExpenseShareCard(
      title: many
          ? 'Combined expense share · all boards'
          : 'Expense share · ${types.first.name}',
      companyAmount: 'PKR ${Money(company).formatted}',
      partnerAmount: 'PKR ${Money(partner).formatted}',
      note: many
          ? 'Total request cost PKR ${Money(total).formatted} across '
                '${_picked.length} boards. Shown before you submit, so '
                'nothing about the cost is a surprise later.'
          : 'Total cost PKR ${Money(total).formatted}, shown as soon as the '
                'board type is picked.',
    );
  }

  /// Board 07 · A4 — nothing is open. An empty state, not an error: for an
  /// installer there is one thing to do about it, and it is offered.
  List<Widget> _noOptions(BrandingOptions options) {
    final needsScan = options.boardTypes.any(
      (type) =>
          !type.available &&
          type.lockedReason == 'Scan a Crown Solar product to open this',
    );

    return [
      DsCard(
        padding: EdgeInsets.zero,
        child: DsEmptyState(
          icon: LucideIcons.panelTopDashed,
          title: 'No Board Options Right Now',
          message: needsScan
              ? 'Frontlit boards open up for installers who have scanned a '
                    'product in the last '
                    '${options.eligibility.scanWindowDays} days. Scan a '
                    'Crown Solar product and come back.'
              : 'Nothing is open to you yet. Sign your scheme or earn more '
                    'points, and the board types will appear here.',
          actionLabel: needsScan ? 'Open Scanner' : null,
          onAction: needsScan ? widget.onOpenScanner : null,
        ),
      ),
      for (final type in options.boardTypes)
        DsOptionCard(
          title: type.name,
          description: type.lockedReason ?? type.condition,
          icon: LucideIcons.lock,
          enabled: false,
        ),
    ];
  }

  Future<void> _pick(int index) async {
    final options = _options!;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BoardTypeSheet(
        options: options,
        selected: _picked[index],
        board: index + 1,
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _picked[index] = chosen);
  }

  Future<void> _submit() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final (created, failure) = await context
        .read<BrandingService>()
        .createRequest(
          mobileNumber: user.mobileNumber,
          shopPhotoPath: _shopPhoto!,
          cardPhotoPath: _cardPhoto!,
          heightFt: double.parse(_height.text.trim()),
          widthFt: double.parse(_width.text.trim()),
          boardCount: _picked.length,
          boardTypeCodes: [for (final code in _picked) code!],
          shopAddress: _address.text.trim(),
          contactNumber: _contact.text.trim(),
          personName: _person.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('Request ${created!.reference} sent.')),
    );
    navigator.pop();
  }
}

/// One BOARD n card: the type picked for it, the condition that opened it,
/// and its own share of the bill.
class _BoardSlot extends StatelessWidget {
  const _BoardSlot({
    required this.index,
    required this.total,
    required this.options,
    required this.selected,
    required this.onChange,
  });

  final int index;
  final int total;
  final BrandingOptions options;
  final String? selected;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final type = selected == null
        ? null
        : options.boardTypes.firstWhere((t) => t.code == selected);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BOARD ${index + 1}',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.06 * 11,
              fontWeight: FontWeight.w600,
              color: context.palette.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type?.name ?? 'Not chosen yet',
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      type?.condition ?? 'Tap Choose to pick a type',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onChange,
                child: Text(
                  type == null ? 'Choose' : 'Change',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (type != null) ...[
            const SizedBox(height: AppSpacing.stepMd),
            const DsHairline(),
            const SizedBox(height: AppSpacing.stepMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: DsCaption(
                    'Company ${type.companyPercent}% · '
                    'You ${type.partnerPercent}%',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'PKR ${type.companyShare.formatted} / '
                    '${type.partnerShare.formatted}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The picker behind Change.
///
/// Locked options are listed rather than hidden, each stating what would
/// open it in the partner's own terms — never the rule that refused it.
class _BoardTypeSheet extends StatelessWidget {
  const _BoardTypeSheet({
    required this.options,
    required this.selected,
    required this.board,
  });

  final BrandingOptions options;
  final String? selected;
  final int board;

  @override
  Widget build(BuildContext context) {
    return DsSheet(
      title: 'Board $board',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in options.boardTypes) ...[
            DsOptionCard(
              title: type.name,
              description: type.available
                  ? '${type.description} · ${type.condition}'
                  : type.lockedReason ?? type.condition,
              icon: type.available ? LucideIcons.panelTop : LucideIcons.lock,
              selected: type.code == selected,
              enabled: type.available,
              trailing: type.available
                  ? Text(
                      'PKR ${type.unitPrice.formatted}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
              onTap: type.available
                  ? () => Navigator.of(context).pop(type.code)
                  : null,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
