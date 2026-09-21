import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/cash_requests_service.dart';

/// Board 04 · B4 — the recipient's inbox.
///
/// The money is already out of the sender's wallet and waiting. Approving
/// moves it into this one; rejecting sends it back. There is no third
/// outcome, which is why both buttons are on every waiting card.
class CashRequestsScreen extends StatefulWidget {
  const CashRequestsScreen({super.key});

  @override
  State<CashRequestsScreen> createState() => _CashRequestsScreenState();
}

class _CashRequestsScreenState extends State<CashRequestsScreen> {
  List<CashRequest>? _requests;
  bool _reachable = true;
  CashRequestState _tab = CashRequestState.waiting;
  String? _deciding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final loaded = await context.read<CashRequestsService>().requests(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() {
      _requests = loaded ?? const [];
      _reachable = loaded != null;
    });
  }

  int get _waiting => [
    for (final request in _requests ?? const <CashRequest>[])
      if (request.waiting) request,
  ].length;

  String get _waitingLabel => 'Waiting · $_waiting';
  static const _approvedLabel = 'Approved';
  static const _rejectedLabel = 'Rejected';

  @override
  Widget build(BuildContext context) {
    final requests = _requests;

    if (requests == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'Cash Requests',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: DsAppBar(
        title: 'Cash Requests',
        subtitle: _waiting == 0 ? null : '$_waiting waiting for you',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsTabs(
              tabs: [_waitingLabel, _approvedLabel, _rejectedLabel],
              value: switch (_tab) {
                CashRequestState.approved => _approvedLabel,
                CashRequestState.rejected => _rejectedLabel,
                _ => _waitingLabel,
              },
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              onChanged: (tab) => setState(() {
                _tab = tab == _approvedLabel
                    ? CashRequestState.approved
                    : tab == _rejectedLabel
                    ? CashRequestState.rejected
                    : CashRequestState.waiting;
              }),
            ),
            Expanded(child: _body(requests)),
          ],
        ),
      ),
    );
  }

  Widget _body(List<CashRequest> requests) {
    // An expired request is money that came back without anyone deciding, so
    // it belongs with the rejections rather than in a fourth tab nobody
    // would think to open.
    final visible = [
      for (final request in requests)
        if (request.state == _tab ||
            (_tab == CashRequestState.rejected &&
                request.state == CashRequestState.expired))
          request,
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          if (visible.isEmpty)
            DsEmptyState(
              icon: _reachable ? LucideIcons.handCoins : LucideIcons.cloudOff,
              title: _reachable ? _emptyTitle : 'Could not reach Crown Solar',
              message: _reachable
                  ? _emptyMessage
                  : 'These requests are held by Crown Solar, not on this '
                        'phone. Check your connection and try again.',
            )
          else ...[
            for (final request in visible) ...[
              _RequestCard(
                request: request,
                busy: _deciding == request.reference,
                onApprove: () => _decide(request, approved: true),
                onReject: () => _decide(request, approved: false),
              ),
              const SizedBox(height: AppSpacing.stepMd),
            ],
            if (_tab == CashRequestState.waiting)
              const DsCaption(
                'Approving moves the held money into your wallet. Rejecting '
                'sends it back to the person who sent it. Either way they '
                'are notified.',
              ),
          ],
        ],
      ),
    );
  }

  String get _emptyTitle => switch (_tab) {
    CashRequestState.waiting => 'Nothing waiting on you',
    CashRequestState.approved => 'Nothing approved yet',
    _ => 'Nothing rejected',
  };

  String get _emptyMessage => switch (_tab) {
    CashRequestState.waiting =>
      'When a partner sends you cash, it waits here until you approve it.',
    CashRequestState.approved =>
      'Requests you approve appear here, with what they added to your wallet.',
    _ => 'Requests you rejected, and any that expired, appear here.',
  };

  Future<void> _decide(CashRequest request, {required bool approved}) async {
    final confirmed = await _confirm(request, approved: approved);
    if (!confirmed || !mounted) return;

    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _deciding = request.reference);
    final messenger = ScaffoldMessenger.of(context);
    final recorded = await context.read<CashRequestsService>().decide(
      mobileNumber: user.mobileNumber,
      reference: request.reference,
      approved: approved,
    );
    if (!mounted) return;

    setState(() => _deciding = null);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          recorded
              ? approved
                    ? 'PKR ${request.amount.formatted} is in your wallet.'
                    : 'PKR ${request.amount.formatted} went back to '
                          '${request.fromName}.'
              : 'Could not record that. Nothing has moved — try again.',
        ),
      ),
    );
    await _load();
  }

  /// Both verdicts are confirmed. Either one moves somebody's money and
  /// neither can be undone from this screen.
  Future<bool> _confirm(CashRequest request, {required bool approved}) async {
    final answer = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: DsDialogCard(
          icon: approved ? LucideIcons.check : LucideIcons.undo2,
          tone: approved ? DsTone.success : DsTone.warning,
          title: approved
              ? 'Accept PKR ${request.amount.formatted}?'
              : 'Send PKR ${request.amount.formatted} back?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DsBody(
                approved
                    ? 'The money moves from held into your wallet straight '
                          'away, and ${request.fromName} is told it arrived.'
                    : 'The money goes back to ${request.fromName} straight '
                          'away. Nothing is added to your wallet.',
                size: 14,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: approved ? 'Approve' : 'Reject',
                variant: approved
                    ? DsButtonVariant.primary
                    : DsButtonVariant.destructive,
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
    return answer == true;
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final CashRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsPartyRow(
            name: request.fromName,
            meta: '${request.fromRole} · ${_when(request.sentAt)}',
            trailing: _trailing(context),
          ),
          const DsHairline(),
          const SizedBox(height: AppSpacing.stepMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const DsCaption('Amount'),
              Text(
                'PKR ${request.amount.formatted}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Only when the sender actually wrote something. An empty note is
          // the same as no note, and an empty line would be noise on every
          // card that has one.
          if (request.note != null && request.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            DsBody(request.note!, size: 13),
          ],
          if (request.waiting) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: DsButton(
                    label: 'Approve',
                    size: DsButtonSize.sm,
                    icon: LucideIcons.check,
                    loading: busy,
                    disabled: busy,
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DsButton(
                    label: 'Reject',
                    variant: DsButtonVariant.secondary,
                    size: DsButtonSize.sm,
                    icon: LucideIcons.x,
                    disabled: busy,
                    onPressed: onReject,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            DsCaption(_outcome),
          ],
        ],
      ),
    );
  }

  /// A waiting request says how long is left; a decided one says what it
  /// became.
  Widget _trailing(BuildContext context) {
    if (!request.waiting) {
      return DsTag(
        label: request.state.label,
        tone: switch (request.state) {
          CashRequestState.approved => DsTone.success,
          CashRequestState.rejected => DsTone.error,
          _ => DsTone.neutral,
        },
      );
    }

    final expires = request.expiresAt;
    if (expires == null) return const DsTag(label: 'Waiting');

    final left = expires.difference(DateTime.now());
    if (left.isNegative) {
      return const DsTag(label: 'Expired', tone: DsTone.error);
    }
    final days = left.inDays;
    return DsTag(
      label: days == 0
          ? 'Expires today'
          : '$days day${days == 1 ? '' : 's'} left',
      tone: days == 0 ? DsTone.error : DsTone.neutral,
    );
  }

  String get _outcome => switch (request.state) {
    CashRequestState.approved =>
      'Approved ${_when(request.decidedAt ?? request.sentAt)}. '
          'Added to your wallet.',
    CashRequestState.rejected =>
      'Rejected ${_when(request.decidedAt ?? request.sentAt)}. '
          'Returned to ${request.fromName}.',
    CashRequestState.expired =>
      'Nobody answered in time, so the money went back automatically.',
    CashRequestState.waiting => '',
  };

  static const _months = [
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

  /// "Today, 9:43 AM", then "Yesterday, 5:20 PM", then "07 Sep".
  static String _when(DateTime at) {
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;

    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final time =
        '$hour:${at.minute.toString().padLeft(2, '0')} '
        '${at.hour < 12 ? 'AM' : 'PM'}';

    if (days == 0) return 'Today, $time';
    if (days == 1) return 'Yesterday, $time';
    return '${at.day.toString().padLeft(2, '0')} ${_months[at.month - 1]}';
  }
}
