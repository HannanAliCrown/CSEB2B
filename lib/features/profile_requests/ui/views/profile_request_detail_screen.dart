import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/profile_requests_service.dart';

/// One new-profile request, opened from the waiting list.
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
  const ProfileRequestDetailScreen({
    super.key,
    required this.request,
    required this.bands,
  });

  final ProfileRequest request;
  final List<ExpectedPurchase> bands;

  @override
  State<ProfileRequestDetailScreen> createState() =>
      _ProfileRequestDetailScreenState();
}

class _ProfileRequestDetailScreenState
    extends State<ProfileRequestDetailScreen> {
  /// What this buying source expects the applicant to buy. Nothing is
  /// pre-selected: a default here would be an answer the partner never gave.
  ExpectedPurchase? _expected;

  bool _busy = false;

  ProfileRequest get _request => widget.request;

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'New Profile',
        subtitle: _request.reference,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
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
      sections: [
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'You are confirming one thing only: that this partner buys from '
              'you. Crown Solar still checks everything else, and their CNIC '
              'stays with CRM.',
        ),

        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _request.businessName,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  DsTag(label: _request.roleLabel, tone: DsTone.info),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DsRowGroup(
                children: [
                  DsSettingRow(label: 'Contact', value: _request.contactName),
                  DsSettingRow(
                    label: 'Mobile',
                    // Read left to right in every language: a number
                    // regrouped by a right-to-left run is a different number.
                    value: '‎+92 ${_request.mobileNumber}‎',
                  ),
                  if (_request.alternateNumber != null)
                    DsSettingRow(
                      label: 'Alternate',
                      value: '‎+92 ${_request.alternateNumber}‎',
                    ),
                  if (_request.marketName != null)
                    DsSettingRow(label: 'Market', value: _request.marketName!),
                  if (_request.businessAddress != null)
                    DsSettingRow(
                      label: 'Shop',
                      value: _request.businessAddress!,
                    ),
                  if (_request.shopLatitude != null &&
                      _request.shopLongitude != null)
                    DsSettingRow(
                      label: 'Shop pin',
                      value:
                          '‎${_request.shopLatitude}, '
                          '${_request.shopLongitude}‎',
                    ),
                ],
              ),
            ],
          ),
        ),

        if (_request.otherBuyingSources.isNotEmpty) ...[
          const DsSectionHeader(title: 'Also buys from'),
          DsRowGroup(
            children: [
              for (final source in _request.otherBuyingSources)
                DsSettingRow(label: source),
            ],
          ),
        ],

        if (_request.media.isNotEmpty) ...[
          const DsSectionHeader(title: 'What they submitted'),
          DsRowGroup(
            children: [
              for (final item in _request.media)
                DsSettingRow(
                  label: item.label,
                  // Videos carry a link; photos live on the applicant's own
                  // phone until file upload is built, so the row says so
                  // rather than offering a tap that cannot work.
                  value: item.openable ? 'Link' : 'Captured',
                  // A URL is too long to sit beside its label — squeezed
                  // into the value slot it breaks "Installation" across
                  // three lines. It gets the full width underneath.
                  meta: item.openable ? item.linkUrl : null,
                ),
            ],
          ),
          const DsCaption(
            'Their CNIC number and CNIC photos are not shown here. Crown '
            'Solar CRM checks those.',
          ),
        ],

        // The required choice. It sits above the buttons because it is a
        // precondition of the approval, not a detail beside it.
        Column(
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
              onTap: widget.bands.isEmpty ? null : _pickExpected,
            ),
          ],
        ),
      ],
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
            for (final band in widget.bands)
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
          title: 'Verify ${_request.businessName}?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DsBody(
                'You are confirming that ${_request.contactName} buys Crown '
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
            title: 'Reject ${_request.businessName}?',
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

  Future<void> _decide({
    required bool approved,
    ExpectedPurchase? band,
    String? reason,
  }) async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final failure = await context.read<ProfileRequestsService>().decide(
      mobileNumber: user.mobileNumber,
      applicationId: _request.applicationId,
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
              ? '${_request.businessName} '
                    '${approved ? 'verified' : 'rejected'}.'
              : failure.message,
        ),
      ),
    );

    // Decided requests leave the waiting list, so there is nothing left on
    // this screen to come back to.
    if (failure == null) navigator.pop(true);
  }
}
