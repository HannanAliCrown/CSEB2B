import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../widgets/registration_scaffold.dart';

/// Board 01 · F1 — Step 6 · Buying source.
///
/// The source is entered by number and the name is looked up, so the partner
/// never types a business name that has to match Crown Solar's records.
class RegistrationSourceScreen extends StatelessWidget {
  const RegistrationSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Buying Source',
      step: 5,
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Continue',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () => PreviewJourney.next(context),
        ),
      ),
      children: [
        const DsBody(
          'Enter the mobile number of who you buy Crown Solar products from — '
          'we look up their name automatically. At least one is required.',
          size: 14,
        ),
        const _SourceCard(
          index: 1,
          label: 'Source 1 · required',
          number: '+92 300 7781204',
          matchedName: 'Al-Noor Electric Store',
          matchedMeta: 'Retailer · Ravi Road · found automatically',
          verifies: true,
        ),
        const _SourceCard(
          index: 2,
          label: 'Source 2 · optional',
          number: '+92 301 4429911',
          matchedName: 'Hamza Solar House',
          matchedMeta: 'Wholesaler · Badami Bagh · found automatically',
        ),
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'Your approval request goes to the first source only — Al-Noor '
              'Electric Store. The others are recorded for Crown Solar\'s '
              'records.',
        ),
        DsButton(
          label: 'Add Another Source',
          variant: DsButtonVariant.secondary,
          icon: LucideIcons.plus,
          onPressed: () {},
        ),
        DsCard(
          tone: DsCardTone.sunken,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Not sure who your buying source is?',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Call the Crown Solar team and they will tell you. You will '
                'come back to this step to enter it.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Contact Team',
                variant: DsButtonVariant.secondary,
                size: DsButtonSize.sm,
                icon: LucideIcons.phone,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.index,
    required this.label,
    required this.number,
    required this.matchedName,
    required this.matchedMeta,
    this.verifies = false,
  });

  final int index;
  final String label;
  final String number;
  final String matchedName;
  final String matchedMeta;
  final bool verifies;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (verifies) const DsTag(label: 'Verifies', tone: DsTone.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsInput(label: 'Mobile number', value: number),
          const SizedBox(height: AppSpacing.stepMd),
          Container(
            padding: const EdgeInsets.all(AppSpacing.stepMd),
            decoration: BoxDecoration(
              color: context.status.successFill,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.circleCheck,
                  size: 18,
                  color: context.status.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        matchedName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.status.success,
                        ),
                      ),
                      Text(
                        matchedMeta,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.status.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 01 · F2 — the number is not a Crown Solar account.
class RegistrationSourceNotFoundScreen extends StatelessWidget {
  const RegistrationSourceNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Buying Source',
      step: 5,
      gap: AppSpacing.md,
      footer: const DsFooterBar(
        child: DsButton(label: 'Continue', disabled: true),
      ),
      children: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Source 1 · required',
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsInput(
                label: 'Mobile number',
                value: '+92 300 0000000',
                error:
                    'No Crown Solar account found for this number. Check the '
                    'digits, or call the team if you are not sure who your '
                    'buying source is.',
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Call Crown Solar · 042 111 276 963',
                variant: DsButtonVariant.secondary,
                size: DsButtonSize.sm,
                icon: LucideIcons.phone,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsNotice(
          icon: LucideIcons.save,
          message:
              'Everything you have entered so far is saved. You can close the '
              'app and come back to this step.',
        ),
      ],
    );
  }
}
