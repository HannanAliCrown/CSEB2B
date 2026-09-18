import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// The expense split shown before a branding request is submitted, so the
/// cost is never a surprise later.
class ExpenseShareCard extends StatelessWidget {
  const ExpenseShareCard({
    super.key,
    required this.title,
    required this.companyAmount,
    required this.partnerAmount,
    required this.note,
  });

  final String title;
  final String companyAmount;
  final String partnerAmount;
  final String note;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.texts.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.stepMd),
          Row(
            children: [
              Expanded(
                child: _ShareCell(
                  label: 'Company share · 60%',
                  value: companyAmount,
                  tone: DsTone.success,
                ),
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: _ShareCell(
                  label: 'Your share · 40%',
                  value: partnerAmount,
                  tone: DsTone.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsCaption(note),
        ],
      ),
    );
  }
}

class _ShareCell extends StatelessWidget {
  const _ShareCell({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final DsTone tone;

  @override
  Widget build(BuildContext context) {
    final (fill, foreground) = dsToneColors(context, tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stepMd),
      decoration: BoxDecoration(color: fill, borderRadius: AppRadii.mdRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              height: 15 / 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 07 · A1 — Module landing: the current request, past requests, and
/// the eligibility facts that decide which board types appear later.
class BrandingLandingScreen extends StatelessWidget {
  const BrandingLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Shop Branding',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
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
              const DsBody(
                'Ask Crown Solar to brand your shop. Takes about five minutes '
                'and two photos.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Start a Request',
                iconAfter: LucideIcons.arrowRight,
                onPressed: () {},
              ),
            ],
          ),
        ),
        DsCard(
          onTap: () {},
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
                        const DsTag(label: 'In Progress', tone: DsTone.info),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const DsCaption(
                      'Backlit Board · installation in progress.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DsSectionHeader(
          title: 'Past requests',
          actionLabel: 'See all',
          onAction: () {},
        ),
        DsCard(
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
              const _EligibilityRow(label: 'Scheme signed', value: 'Yes'),
              const DsHairline(),
              const _EligibilityRow(label: 'Points balance', value: '182,400'),
              const DsHairline(),
              const _EligibilityRow(
                label: 'Existing board',
                value: 'Backlit · under 6 months old',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsCaption(
                'Board types are decided when you submit, from your points, '
                'scheme and existing board.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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

/// Board 07 · A2 — Step 1 · shop details, photos and board measurements.
class BrandingRequestFormScreen extends StatelessWidget {
  const BrandingRequestFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {},
        ),
      ),
      sections: [
        Row(
          children: const [
            Expanded(
              child: DsUploadRow(
                label: 'Shop picture',
                state: DsUploadState.uploaded,
                meta: 'Added',
                icon: LucideIcons.camera,
              ),
            ),
          ],
        ),
        const DsUploadRow(
          label: 'Visiting card',
          state: DsUploadState.empty,
          meta: 'Required',
          icon: LucideIcons.idCard,
        ),
        const Row(
          children: [
            Expanded(
              child: DsInput(label: 'Board height', value: '4', unit: 'ft'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: DsInput(label: 'Board width', value: '12', unit: 'ft'),
            ),
          ],
        ),
        const DsInput(label: 'Number of boards', value: '2'),
        Text(
          'OPTIONAL',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        const DsInput(
          label: 'Shop address',
          placeholder: 'If different from your profile',
        ),
        const DsInput(label: 'Contact number', placeholder: 'Optional'),
        const DsInput(label: "Person's name", placeholder: 'Optional'),
      ],
    );
  }
}

/// One board-type option, with the condition that unlocked it and its own
/// expense split.
class _BoardTypeCard extends StatelessWidget {
  const _BoardTypeCard({
    required this.index,
    required this.name,
    required this.condition,
    required this.share,
    required this.amounts,
  });

  final String index;
  final String name;
  final String condition;
  final String share;
  final String amounts;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index,
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
                      name,
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      condition,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Change',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          const DsHairline(),
          const SizedBox(height: AppSpacing.stepMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DsCaption(share),
              Text(
                amounts,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Board 07 · A3 — Board type for a Retailer with points and a scheme; each
/// requested board can be a different type.
class BrandingBoardTypeScreen extends StatelessWidget {
  const BrandingBoardTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Board Type',
        subtitle: 'Step 2 of 3 · 2 boards requested',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Review Request',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () {},
        ),
      ),
      sections: [
        const DsBody(
          'Available to you as a Retailer with a signed scheme and 182,400 '
          'points. Each board below can be a different type.',
          size: 14,
        ),
        const _BoardTypeCard(
          index: 'BOARD 1',
          name: 'Backlit Board',
          condition: 'Scheme signed',
          share: 'Company 60% · You 40%',
          amounts: 'PKR 48,000 / 32,000',
        ),
        const _BoardTypeCard(
          index: 'BOARD 2',
          name: 'Inverter Wall Branding',
          condition: '15,000 points and a signed scheme',
          share: 'Company 60% · You 40%',
          amounts: 'PKR 18,000 / 12,000',
        ),
        const ExpenseShareCard(
          title: 'Combined expense share · both boards',
          companyAmount: 'PKR 66,000',
          partnerAmount: 'PKR 44,000',
          note:
              'Total request cost PKR 110,000 across 2 boards. Shown before '
              'you submit, so nothing about the cost is a surprise later.',
        ),
        const DsCaption(
          'Locked options — such as those needing 100,000 points, or '
          'wholesaler and distributor only — state their own condition when '
          'you tap Change.',
        ),
      ],
    );
  }
}

/// Board 07 · A4 — Installer: Frontlit needs a recent scan, and the
/// ineligible state names the one thing the installer can do about it.
class BrandingInstallerScreen extends StatelessWidget {
  const BrandingInstallerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Board Type',
        subtitle: 'Step 2 of 3 · Installer',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsOptionCard(
          title: 'Frontlit Board',
          description: 'Available because you scanned a product 3 days ago',
          icon: LucideIcons.panelTop,
          selected: true,
          onTap: () {},
        ),
        const DsNotice(
          icon: LucideIcons.scanLine,
          tone: DsTone.success,
          message:
              'You scanned recently. Keep scanning to keep this option open.',
        ),
        const ExpenseShareCard(
          title: 'Expense share · Frontlit Board',
          companyAmount: 'PKR 27,000',
          partnerAmount: 'PKR 18,000',
          note:
              'Total cost PKR 45,000, shown as soon as the board type is '
              'picked.',
        ),
        Text(
          'IF NO SCAN IN 10 DAYS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.panelTopDashed,
            title: 'No Board Options Right Now',
            message:
                'Frontlit boards open up for installers who have scanned a '
                'product in the last 10 days. Scan a Crown Solar product and '
                'come back.',
            actionLabel: 'Open Scanner',
            onAction: () {},
          ),
        ),
        const DsCaption(
          'The ineligible state names the one thing the installer can do about '
          'it, with the action attached.',
        ),
      ],
    );
  }
}

/// Board 07 · A5 — Replacement detected: a board under six months old leaves
/// exactly one option, and the screen says so plainly.
class BrandingReplacementScreen extends StatelessWidget {
  const BrandingReplacementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Board Type',
        subtitle: 'Step 2 of 3',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Review Request',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () {},
        ),
      ),
      sections: [
        const DsNotice(
          icon: LucideIcons.info,
          tone: DsTone.info,
          title: 'You already have a Backlit board',
          message:
              'Installed less than six months ago. While it is this new, the '
              'only option is a skin change on the existing board.',
        ),
        DsOptionCard(
          title: 'Backlit Skin Change',
          description: 'New printed skin on your existing frame',
          icon: LucideIcons.refreshCw,
          selected: true,
          onTap: () {},
        ),
        const ExpenseShareCard(
          title: 'Expense share · Backlit Skin Change',
          companyAmount: 'PKR 12,000',
          partnerAmount: 'PKR 8,000',
          note:
              'Total cost PKR 20,000, lower than a new board since only the '
              'skin is replaced.',
        ),
        const DsCaption(
          'Frontlit, Backlit, wall branding, vinyl and One Way Vision are not '
          'offered right now, even though your points and scheme would allow '
          'them.',
        ),
        const DsCaption(
          'A Frontlit board under six months old behaves the same way, '
          'offering Frontlit Flex Change only.',
        ),
      ],
    );
  }
}
