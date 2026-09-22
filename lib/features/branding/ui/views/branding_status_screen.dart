import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/branding_service.dart';

/// Board 07 · A6 · A8 · A9 — one request: where it is, and the money split
/// that was agreed when it was submitted.
///
/// A live request and a finished one share the timeline; a rejected one
/// shows the reason instead, since no stage past review was ever reached.
class BrandingStatusScreen extends StatefulWidget {
  const BrandingStatusScreen({
    super.key,
    required this.reference,
    required this.onNewRequest,
  });

  final String reference;
  final Future<void> Function() onNewRequest;

  @override
  State<BrandingStatusScreen> createState() => _BrandingStatusScreenState();
}

class _BrandingStatusScreenState extends State<BrandingStatusScreen> {
  BrandingRequest? _request;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    final request = await context.read<BrandingService>().request(
      mobileNumber: user.mobileNumber,
      reference: widget.reference,
    );
    if (!mounted) return;
    setState(() {
      _request = request;
      _missing = request == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    if (request == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'Request Status',
          subtitle: widget.reference,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: _missing
            ? const DsEmptyState(
                icon: LucideIcons.fileQuestion,
                title: 'Request not found',
                message:
                    'Could not load this request. Go back and open it again.',
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: DsAppBar(
        title: request.inProgress ? 'Request Status' : 'Request Summary',
        subtitle: '${request.reference} · ${request.boardSummary}',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: request.rejected
                ? _rejected(request)
                : _timeline(request),
          ),
        ),
      ),
    );
  }

  // --- A6 · A8 --------------------------------------------------------------

  List<Widget> _timeline(BrandingRequest request) => [
    if (request.completed) ...[
      DsCard(
        tone: DsCardTone.sunken,
        child: Row(
          children: [
            const DsIconMedallion(
              icon: LucideIcons.circleCheck,
              tone: DsTone.success,
              size: 40,
              iconSize: 20,
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Completed',
                    style: context.texts.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const DsCaption('All stages finished'),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ],
    _progress(request),
    const SizedBox(height: AppSpacing.md),
    _moneyRows(request),
    if (request.boards.length > 1) ...[
      const SizedBox(height: AppSpacing.md),
      _boardBreakdown(request),
    ],
  ];

  Widget _progress(BrandingRequest request) {
    const titles = ['Approved', 'Board Installed', 'Call Confirmation'];
    // A completed request shows every stage resolved rather than a live
    // position, so the timeline still reads as a history.
    final reached = request.completed ? 4 : request.stage;
    final meta = [
      'Crown Solar branding team',
      request.completed
          ? '${request.boardSummary} installed'
          : 'Installation in progress',
      request.completed
          ? 'Confirmed complete with Crown Solar'
          : 'Crown Solar will call you to confirm the work',
    ];

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: context.texts.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DsTimeline(
            steps: [
              for (var i = 0; i < titles.length; i++)
                DsTimelineStep(
                  title: titles[i],
                  meta: meta[i],
                  done: i < reached - 1,
                  active: i == reached - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moneyRows(BrandingRequest request) => DsRowGroup(
    children: [
      // One board names itself; several are counted here and named one by
      // one in the breakdown below, so this row never has to carry a list.
      DsSettingRow(
        label: 'Board type',
        value: request.boards.length == 1
            ? request.boards.single.name
            : '${request.boards.length} boards',
        meta: request.dimensions,
      ),
      DsSettingRow(
        label: 'Company share',
        value: 'PKR ${request.company.formatted} · ${request.companyPercent}%',
      ),
      DsSettingRow(
        label: 'Your share',
        value: 'PKR ${request.partner.formatted} · ${request.partnerPercent}%',
      ),
    ],
  );

  /// With more than one board the totals above are a sum, so each board is
  /// named with what it contributed.
  Widget _boardBreakdown(BrandingRequest request) => DsRowGroup(
    children: [
      for (final board in request.boards)
        DsSettingRow(
          label: 'Board ${board.position}',
          value: 'PKR ${board.company.formatted} / ${board.partner.formatted}',
          meta: board.name,
        ),
    ],
  );

  // --- A9 -------------------------------------------------------------------

  List<Widget> _rejected(BrandingRequest request) => [
    DsCard(
      radius: AppRadii.heroRadius,
      padding: const EdgeInsets.all(AppSpacing.stepLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.circleX,
                tone: DsTone.error,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rejected', style: context.texts.titleLarge),
                    const DsCaption('Crown Solar branding team'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.status.errorFill,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REASON GIVEN',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                    color: context.status.error,
                  ),
                ),
                const SizedBox(height: 6),
                DsBody(
                  request.rejectionReason ??
                      'Crown Solar did not record a reason.',
                  color: context.status.error,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    DsButton(
      label: 'Start a New Request',
      onPressed: () async {
        await widget.onNewRequest();
        if (mounted) await _load();
      },
    ),
  ];
}
