import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/profile_requests_service.dart';

/// New Profile — one request, and the verdict on it.
///
/// Two things are required and neither can be skipped: approving names what
/// the applicant is expected to buy, and rejecting gives a reason the
/// applicant is told. Both are enforced by the database as well as here.
///
/// What is deliberately absent: the CNIC number and the CNIC images. A
/// buying source is confirming that someone buys from them, not identifying
/// them — the identity documents stay with CRM and are never selected for
/// this screen.
class ProfileRequestDetailScreen extends StatefulWidget {
  const ProfileRequestDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  State<ProfileRequestDetailScreen> createState() =>
      _ProfileRequestDetailScreenState();
}

class _ProfileRequestDetailScreenState
    extends State<ProfileRequestDetailScreen> {
  ProfileRequest? _request;
  List<ExpectedPurchase> _bands = const [];
  bool _loaded = false;
  bool _busy = false;

  /// What this buying source expects the applicant to buy. Nothing is
  /// pre-selected: a default here would be an answer the partner never gave.
  ExpectedPurchase? _expected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final service = context.read<ProfileRequestsService>();

    final pending = await service.pending(user.mobileNumber);
    final bands = await service.expectedPurchases();
    if (!mounted) return;
    setState(() {
      _request = pending
          ?.where((request) => request.applicationId == widget.applicationId)
          .firstOrNull;
      _bands = bands;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    if (!_loaded) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'New Profile',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // A request decided elsewhere, or one this partner was never asked
    // about, is gone rather than wrong — the inbox is where it was.
    if (request == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'New Profile',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: DsEmptyState(
            icon: LucideIcons.userCheck,
            title: 'This request is no longer waiting',
            message:
                'It has already been decided, or it was never assigned to '
                'you. Go back to see what is still outstanding.',
          ),
        ),
      );
    }

    return DsScreen(
      appBar: DsAppBar(
        title: request.businessName,
        subtitle: request.reference,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      sections: [
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'You are confirming one thing only: that this partner buys '
              'from you. Crown Solar still checks everything else, and their '
              'CNIC stays with CRM.',
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.businessName,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DsTag(label: request.roleLabel, tone: DsTone.info),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DsRowGroup(
                children: [
                  DsSettingRow(label: 'Contact', value: request.contactName),
                  DsSettingRow(
                    label: 'Mobile',
                    // Read left to right in every language: a number
                    // regrouped by a right-to-left run is a different number.
                    value: '‎+92 ${request.mobileNumber}‎',
                  ),
                  if (request.alternateNumber != null)
                    DsSettingRow(
                      label: 'Alternate',
                      value: '‎+92 ${request.alternateNumber}‎',
                    ),
                  if (request.marketName != null)
                    DsSettingRow(label: 'Market', value: request.marketName!),
                  if (request.businessAddress != null)
                    DsSettingRow(
                      label: 'Shop',
                      value: request.businessAddress!,
                    ),
                  if (request.shopLatitude != null &&
                      request.shopLongitude != null)
                    DsSettingRow(
                      label: 'Shop pin',
                      value:
                          '‎${request.shopLatitude}, '
                          '${request.shopLongitude}‎',
                    ),
                ],
              ),
            ],
          ),
        ),
        if (request.otherBuyingSources.isNotEmpty)
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DsSectionHeader(title: 'Also buys from'),
                DsRowGroup(
                  children: [
                    for (final source in request.otherBuyingSources)
                      DsSettingRow(label: source),
                  ],
                ),
              ],
            ),
          ),
        if (request.media.isNotEmpty)
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DsSectionHeader(title: 'What they submitted'),
                DsRowGroup(
                  children: [
                    for (final item in request.media)
                      DsSettingRow(
                        label: item.label,
                        // Videos carry a link; photos live on the applicant's
                        // own phone until file upload is built, so the row
                        // says so rather than offering a tap that cannot
                        // work.
                        value: item.openable ? 'Link' : 'Captured',
                        // A URL is too long to sit beside its label —
                        // squeezed into the value slot it breaks
                        // "Installation" across three lines. It gets the full
                        // width underneath.
                        meta: item.openable ? item.linkUrl : null,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                const DsCaption(
                  'Their CNIC number and CNIC photos are not shown here. '
                  'Crown Solar CRM checks those.',
                ),
              ],
            ),
          ),

        // The required choice. It sits above the buttons because it is a
        // precondition of the approval, not a detail beside it.
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What do you expect them to buy from you?',
                style: context.texts.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DsSelect(
                value: _expected?.label,
                placeholder: 'Choose a monthly figure',
                onTap: _bands.isEmpty ? null : _pickExpected,
              ),
            ],
          ),
        ),
      ],
      footer: DsFooterBar(
        child: Row(
          children: [
            Expanded(
              child: DsButton(
                label: 'Reject',
                variant: DsButtonVariant.quiet,
                disabled: _busy,
                onPressed: _askForReason,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DsButton(
                label: 'Verify',
                loading: _busy,
                // Disabled until the expectation is given, so the rule is
                // visible before it is enforced.
                disabled: _busy || _expected == null,
                onPressed: () => _confirmApproval(_expected!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpected() async {
    final chosen = await showModalBottomSheet<ExpectedPurchase>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DsSheet(
        title: 'Expected purchasing',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final band in _bands)
              DsRadio(
                selected: _expected?.id == band.id,
                label: band.label,
                onTap: () => Navigator.of(context).pop(band),
              ),
            // Clears the phone's navigation bar so the last band is not cut
            // off beneath it.
            SizedBox(
              height: MediaQuery.viewPaddingOf(context).bottom + AppSpacing.sm,
            ),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _expected = chosen);
  }

  Future<void> _confirmApproval(ExpectedPurchase band) async {
    final request = _request!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: DsDialogCard(
          icon: LucideIcons.userCheck,
          tone: DsTone.success,
          title: 'Verify ${request.businessName}?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DsBody(
                'You are confirming that ${request.contactName} buys Crown '
                'Solar products from you, at about ${band.label}. The '
                'marketing officer and CRM still have to approve them as '
                'well.',
                size: 14,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Verify',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 10),
              DsButton(
                label: 'Cancel',
                variant: DsButtonVariant.quiet,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) await _decide(approved: true, band: band);
  }

  /// A rejection ends the application, so the reason is asked for here
  /// rather than being optional afterwards.
  Future<void> _askForReason() async {
    final request = _request!;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: StatefulBuilder(
          builder: (context, setDialogState) => DsDialogCard(
            icon: LucideIcons.userX,
            tone: DsTone.error,
            title: 'Reject ${request.businessName}?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const DsBody(
                  'This ends their application. They are told the reason, so '
                  'say what it is.',
                  size: 14,
                ),
                const SizedBox(height: AppSpacing.md),
                DsInput(
                  label: 'Reason',
                  controller: controller,
                  placeholder: 'They do not buy from us',
                  maxLines: 3,
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                DsButton(
                  label: 'Reject',
                  variant: DsButtonVariant.destructive,
                  disabled: controller.text.trim().isEmpty,
                  onPressed: () =>
                      Navigator.of(context).pop(controller.text.trim()),
                ),
                const SizedBox(height: 10),
                DsButton(
                  label: 'Cancel',
                  variant: DsButtonVariant.quiet,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();

    if (reason != null && reason.isNotEmpty) {
      await _decide(approved: false, reason: reason);
    }
  }

  /// Records the verdict and, when it is recorded, leaves — the request is
  /// no longer waiting, so the inbox is the right place to be.
  Future<void> _decide({
    required bool approved,
    ExpectedPurchase? band,
    String? reason,
  }) async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final request = _request!;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final failure = await context.read<ProfileRequestsService>().decide(
      mobileNumber: user.mobileNumber,
      applicationId: request.applicationId,
      approved: approved,
      expectedPurchaseId: band?.id,
      note: reason,
    );
    if (!mounted) return;

    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? '${request.businessName} '
                    '${approved ? 'verified' : 'rejected'}.'
              : failure.message,
        ),
      ),
    );
    if (failure == null) navigator.pop(true);
  }
}
