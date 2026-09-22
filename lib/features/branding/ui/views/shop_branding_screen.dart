import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/branding_service.dart';

/// Board 07 · A1 — Module landing: the current request, past requests, and
/// the eligibility facts that decide which board types appear later.
///
/// The eligibility summary is shown up front so a partner does not fill in a
/// form to be told no at the end.
class ShopBrandingScreen extends StatefulWidget {
  const ShopBrandingScreen({
    super.key,
    required this.onNewRequest,
    required this.onOpenRequest,
    required this.onSeeAll,
  });

  /// Awaited, so the landing reloads rather than showing the position from
  /// before a request was filed.
  final Future<void> Function() onNewRequest;
  final Future<void> Function(String reference) onOpenRequest;
  final Future<void> Function() onSeeAll;

  @override
  State<ShopBrandingScreen> createState() => _ShopBrandingScreenState();
}

class _ShopBrandingScreenState extends State<ShopBrandingScreen> {
  BrandingLanding? _landing;
  bool _reachable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    final landing = await context.read<BrandingService>().landing(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() {
      _landing = landing ?? BrandingLanding.empty;
      _reachable = landing != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final landing = _landing;
    if (landing == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'Shop Branding',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: DsAppBar(
        title: 'Shop Branding',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              if (!_reachable) ...[
                const DsNotice(
                  icon: LucideIcons.cloudOff,
                  tone: DsTone.warning,
                  message:
                      'Could not reach Crown Solar, so nothing here is your '
                      'real position. Pull down to try again.',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _newRequestCard(landing),
              const SizedBox(height: AppSpacing.md),
              if (landing.current != null) ...[
                _currentRequestCard(landing.current!),
                const SizedBox(height: AppSpacing.md),
              ],
              if (landing.requests.isNotEmpty) ...[
                DsSectionHeader(
                  title: 'Past requests',
                  actionLabel: landing.requests.length > 1 ? 'See all' : null,
                  onAction: () async {
                    await widget.onSeeAll();
                    await _load();
                  },
                ),
                _pastRequestsCard(landing),
                const SizedBox(height: AppSpacing.md),
              ],
              _eligibilityCard(landing.eligibility),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newRequestCard(BrandingLanding landing) {
    // One live request at a time, so while one is moving the card explains
    // that rather than offering a button that would be refused.
    final blocked = landing.current != null;

    return DsCard(
      tone: DsCardTone.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.store,
                size: 44,
                iconSize: 22,
                rounded: true,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Text('New Request', style: context.texts.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsBody(
            blocked
                ? 'Crown Solar finishes one request before starting the '
                      'next. Yours is still in progress.'
                : 'Ask Crown Solar to brand your shop. Takes about five '
                      'minutes and two photos.',
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsButton(
            label: 'Start a Request',
            iconAfter: LucideIcons.arrowRight,
            disabled: blocked,
            onPressed: blocked
                ? null
                : () async {
                    await widget.onNewRequest();
                    await _load();
                  },
          ),
        ],
      ),
    );
  }

  Widget _currentRequestCard(BrandingRequest request) {
    return DsCard(
      onTap: () async {
        await widget.onOpenRequest(request.reference);
        await _load();
      },
      child: Row(
        children: [
          const DsIconMedallion(
            icon: LucideIcons.hardHat,
            tone: DsTone.info,
            size: 40,
            iconSize: 20,
            rounded: true,
          ),
          const SizedBox(width: AppSpacing.stepMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current Request Status',
                        style: context.texts.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const DsTag(label: 'In Progress', tone: DsTone.info),
                  ],
                ),
                const SizedBox(height: 2),
                DsCaption(
                  '${request.boardSummary} · ${_stageLine(request.stage)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _stageLine(int stage) => switch (stage) {
    1 => 'approved, waiting on installation',
    2 => 'installation in progress',
    _ => 'waiting on the confirmation call',
  };

  Widget _pastRequestsCard(BrandingLanding landing) {
    // Three, then "See all" — the landing names what happened without
    // becoming the history screen.
    final visible = landing.requests.take(3).toList();

    return DsCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            DsSettingRow(
              label: visible[i].boardSummary,
              meta: visible[i].reference,
              trailing: DsTag(
                label: statusLabel(visible[i]),
                tone: statusTone(visible[i]),
              ),
              onTap: () async {
                await widget.onOpenRequest(visible[i].reference);
                await _load();
              },
            ),
            if (i != visible.length - 1) const DsHairline(),
          ],
        ],
      ),
    );
  }

  Widget _eligibilityCard(BrandingEligibility eligibility) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your eligibility right now',
            style: context.texts.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _EligibilityRow(
            label: 'Scheme signed',
            value: eligibility.schemeSigned ? 'Yes' : 'No',
          ),
          const DsHairline(),
          _EligibilityRow(
            label: 'Points balance',
            value: eligibility.pointsFormatted,
          ),
          const DsHairline(),
          _EligibilityRow(
            label: 'Existing board',
            value: eligibility.existingBoardLabel,
          ),
          const SizedBox(height: AppSpacing.stepMd),
          const DsCaption(
            'Board types are decided when you submit, from your points, '
            'scheme and existing board.',
          ),
        ],
      ),
    );
  }
}

/// The pill a request's outcome wears, in the list and on its own screen.
String statusLabel(BrandingRequest request) => switch (request.status) {
  'completed' => 'Completed',
  'rejected' => 'Rejected',
  _ => 'In Progress',
};

DsTone statusTone(BrandingRequest request) => switch (request.status) {
  'completed' => DsTone.success,
  'rejected' => DsTone.error,
  _ => DsTone.info,
};

class _EligibilityRow extends StatelessWidget {
  const _EligibilityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: DsBody(label, size: 14)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
