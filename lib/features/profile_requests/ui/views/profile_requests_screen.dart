import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/profile_requests_service.dart';

/// New Profile — the buying source's side of a registration.
///
/// Someone applying to Crown Solar names where they buy from. This is what
/// that partner sees, so they can say whether it is true.
///
/// Two things are required and neither can be skipped: approving names what
/// the applicant is expected to buy, and rejecting gives a reason the
/// applicant is told. Both are enforced by the database as well as here.
///
/// What is deliberately absent: the CNIC number and the CNIC images. A
/// buying source is confirming that someone buys from them, not identifying
/// them — the identity documents stay with CRM and are never selected for
/// this screen.
class ProfileRequestsScreen extends StatefulWidget {
  const ProfileRequestsScreen({super.key});

  @override
  State<ProfileRequestsScreen> createState() => _ProfileRequestsScreenState();
}

class _ProfileRequestsScreenState extends State<ProfileRequestsScreen> {
  List<ProfileRequest>? _requests;
  List<ExpectedPurchase> _bands = const [];
  bool _reachable = true;
  String? _deciding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final service = context.read<ProfileRequestsService>();

    final loaded = await service.pending(user.mobileNumber);
    final bands = await service.expectedPurchases();
    if (!mounted) return;
    setState(() {
      _requests = loaded ?? const [];
      _bands = bands;
      _reachable = loaded != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = _requests;

    if (requests == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'New Profile',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: DsAppBar(
        title: 'New Profile',
        subtitle: requests.isEmpty ? null : '${requests.length} waiting on you',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              if (requests.isEmpty)
                DsEmptyState(
                  icon: _reachable
                      ? LucideIcons.userCheck
                      : LucideIcons.cloudOff,
                  title: _reachable
                      ? 'Nothing waiting on you'
                      : 'Could not reach Crown Solar',
                  message: _reachable
                      ? 'When someone registers and names you as their buying '
                            'source, their request appears here.'
                      : 'These requests are held by Crown Solar, not on this '
                            'phone. Check your connection and try again.',
                )
              else ...[
                const DsNotice(
                  icon: LucideIcons.info,
                  message:
                      'You are confirming one thing only: that this partner '
                      'buys from you. Crown Solar still checks everything '
                      'else, and their CNIC stays with CRM.',
                ),
                const SizedBox(height: AppSpacing.stepMd),
                for (final request in requests) ...[
                  _RequestCard(
                    request: request,
                    bands: _bands,
                    busy: _deciding == request.applicationId,
                    onApprove: (band) =>
                        _decide(request, approved: true, band: band),
                    onReject: (reason) =>
                        _decide(request, approved: false, reason: reason),
                  ),
                  const SizedBox(height: AppSpacing.stepMd),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _decide(
    ProfileRequest request, {
    required bool approved,
    ExpectedPurchase? band,
    String? reason,
  }) async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _deciding = request.applicationId);
    final messenger = ScaffoldMessenger.of(context);
    final failure = await context.read<ProfileRequestsService>().decide(
      mobileNumber: user.mobileNumber,
      applicationId: request.applicationId,
      approved: approved,
      expectedPurchaseId: band?.id,
      note: reason,
    );
    if (!mounted) return;

    setState(() => _deciding = null);
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
    await _load();
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({
    required this.request,
    required this.bands,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final ProfileRequest request;
  final List<ExpectedPurchase> bands;
  final bool busy;
  final ValueChanged<ExpectedPurchase> onApprove;
  final ValueChanged<String> onReject;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  /// What this buying source expects the applicant to buy. Nothing is
  /// pre-selected: a default here would be an answer the partner never gave.
  ExpectedPurchase? _expected;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.reference,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
              ),
              DsTag(label: request.roleLabel, tone: DsTone.info),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.businessName,
            style: context.texts.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DsRowGroup(
            children: [
              DsSettingRow(label: 'Contact', value: request.contactName),
              DsSettingRow(
                label: 'Mobile',
                // Read left to right in every language: a number regrouped
                // by a right-to-left run is a different number.
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
                DsSettingRow(label: 'Shop', value: request.businessAddress!),
              if (request.shopLatitude != null && request.shopLongitude != null)
                DsSettingRow(
                  label: 'Shop pin',
                  value:
                      '‎${request.shopLatitude}, '
                      '${request.shopLongitude}‎',
                ),
            ],
          ),
          if (request.otherBuyingSources.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stepMd),
            const DsSectionHeader(title: 'Also buys from'),
            DsRowGroup(
              children: [
                for (final source in request.otherBuyingSources)
                  DsSettingRow(label: source),
              ],
            ),
          ],
          if (request.media.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stepMd),
            const DsSectionHeader(title: 'What they submitted'),
            DsRowGroup(
              children: [
                for (final item in request.media)
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
            const SizedBox(height: 6),
            const DsCaption(
              'Their CNIC number and CNIC photos are not shown here. Crown '
              'Solar CRM checks those.',
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // The required choice. It sits above the buttons because it is a
          // precondition of the approval, not a detail beside it.
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DsButton(
                  label: 'Reject',
                  variant: DsButtonVariant.quiet,
                  disabled: widget.busy,
                  onPressed: _askForReason,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DsButton(
                  label: 'Verify',
                  loading: widget.busy,
                  // Disabled until the expectation is given, so the rule is
                  // visible before it is enforced.
                  disabled: widget.busy || _expected == null,
                  onPressed: () => _confirmApproval(_expected!),
                ),
              ),
            ],
          ),
        ],
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
            for (final band in widget.bands)
              DsRadio(
                selected: _expected?.id == band.id,
                label: band.label,
                onTap: () => Navigator.of(context).pop(band),
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
          title: 'Verify ${widget.request.businessName}?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DsBody(
                'You are confirming that ${widget.request.contactName} buys '
                'Crown Solar products from you, at about ${band.label}. The '
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
    if (confirmed == true) widget.onApprove(band);
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
            title: 'Reject ${widget.request.businessName}?',
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

    if (reason != null && reason.isNotEmpty) widget.onReject(reason);
  }
}
