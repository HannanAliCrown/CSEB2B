import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// The three-stage progress every branding request moves through.
class _BrandingProgress extends StatelessWidget {
  const _BrandingProgress({required this.stage, required this.meta});

  /// 1 = approved, 2 = installed, 3 = call confirmed.
  final int stage;
  final List<String> meta;

  @override
  Widget build(BuildContext context) {
    const titles = ['Approved', 'Board Installed', 'Call Confirmation'];
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
                  done: i < stage - 1,
                  active: i == stage - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Board 07 · A6 — Request Summary: where the request is, and the money split
/// that was agreed when it was submitted.
class BrandingRequestSummaryScreen extends StatelessWidget {
  const BrandingRequestSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Request Status',
        subtitle: 'BRD-2026-3391 · Backlit Board',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        const _BrandingProgress(
          stage: 2,
          meta: [
            'Crown Solar branding team',
            'Installation in progress',
            'Crown Solar will call you to confirm the work',
          ],
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(
              label: 'Board type',
              value: 'Backlit Board',
              meta: '4 ft × 12 ft × 2',
            ),
            DsSettingRow(label: 'Company share', value: 'PKR 48,000 · 60%'),
            DsSettingRow(label: 'Your share', value: 'PKR 32,000 · 40%'),
          ],
        ),
      ],
    );
  }
}

/// Board 07 · A7 — Past Requests: tap one for its summary.
class BrandingPastRequestsScreen extends StatelessWidget {
  const BrandingPastRequestsScreen({super.key});

  static const _requests = [
    ('Backlit Board', 'BRD-2026-3391', 'In Progress', DsTone.info),
    ('Frontlit Board', 'BRD-2026-2988', 'Completed', DsTone.success),
    ('Inverter Wall Branding', 'BRD-2025-9147', 'Completed', DsTone.success),
    ('Vinyl Pasting', 'BRD-2025-6602', 'Rejected', DsTone.error),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Past Requests',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      sections: [
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < _requests.length; i++) ...[
                DsSettingRow(
                  label: _requests[i].$1,
                  meta: _requests[i].$2,
                  trailing: DsTag(
                    label: _requests[i].$3,
                    tone: _requests[i].$4,
                  ),
                  onTap: () {},
                ),
                if (i != _requests.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 07 · A8 — A completed request, with every stage finished.
class BrandingCompletedScreen extends StatelessWidget {
  const BrandingCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Request Summary',
        subtitle: 'BRD-2026-2988 · Frontlit Board',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
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
        const _BrandingProgress(
          stage: 4,
          meta: [
            'Crown Solar branding team',
            'Frontlit board installed',
            'Confirmed complete with Crown Solar',
          ],
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(
              label: 'Board type',
              value: 'Frontlit Board',
              meta: '4 ft × 10 ft × 1',
            ),
            DsSettingRow(label: 'Company share', value: 'PKR 36,000 · 60%'),
            DsSettingRow(label: 'Your share', value: 'PKR 24,000 · 40%'),
          ],
        ),
      ],
    );
  }
}

/// Board 07 · A9 — A rejected request, with the reason and the one way
/// forward.
class BrandingRejectedScreen extends StatelessWidget {
  const BrandingRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Request Summary',
        subtitle: 'BRD-2025-6602 · Vinyl Pasting',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
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
                      'Wall surface is not suitable for vinyl pasting — too '
                      'much surface damage to hold the material.',
                      color: context.status.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DsButton(label: 'Start a New Request', onPressed: () {}),
      ],
    );
  }
}
