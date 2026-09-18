import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../../data/models/registration_draft.dart';
import '../registration_scope.dart';
import '../widgets/registration_scaffold.dart';

/// Board 01 · F1 — Step 6 · Buying source.
///
/// The source is entered by number and the name is looked up, so the partner
/// never types a business name that has to match Crown Solar's records.
class RegistrationSourceScreen extends StatefulWidget {
  const RegistrationSourceScreen({super.key});

  @override
  State<RegistrationSourceScreen> createState() =>
      _RegistrationSourceScreenState();
}

class _RegistrationSourceScreenState extends State<RegistrationSourceScreen> {
  final _controllers = <int, TextEditingController>{};

  /// Rows the partner has asked for. One source is required, so the step
  /// opens with a single row; "Add Another Source" adds the next one.
  int _requestedRows = 1;

  /// Never fewer rows than there are sources already entered, so a resumed
  /// draft shows everything it holds.
  int _rowCount(int entered) =>
      _requestedRows > entered ? _requestedRows : entered;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final sources = flow?.draft.buyingSources ?? const <BuyingSourceEntry>[];
    final rows = flow == null ? 2 : _rowCount(sources.length);
    final verifyingName = flow == null
        ? 'Al-Noor Electric Store'
        : (sources.isEmpty ? 'your first source' : sources.first.summary);

    return RegistrationScaffold(
      title: 'Buying Source',
      step: 5,
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Continue',
          iconAfter: LucideIcons.arrowRight,
          onPressed: flow == null
              ? () => PreviewJourney.next(context)
              : flow.next,
        ),
      ),
      children: [
        const DsBody(
          'Enter the mobile number of who you buy Crown Solar products from — '
          'we look up their name automatically. At least one is required.',
          size: 14,
        ),
        if (flow == null) ...[
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
        ] else
          for (var i = 0; i < rows; i++)
            _SourceCard(
              index: i + 1,
              label: i == 0
                  ? 'Source 1 · required'
                  : 'Source ${i + 1} · optional',
              verifies: i == 0,
              controller: _controllers.putIfAbsent(
                i,
                () => TextEditingController(
                  text: i < sources.length ? sources[i].mobileNumber : '',
                ),
              ),
              matchedName: i < sources.length ? sources[i].matchedName : null,
              matchedMeta: i < sources.length && sources[i].isFound
                  ? '${sources[i].matchedRole} · ${sources[i].matchedMarket} · '
                        'found automatically'
                  : null,
              notFound: i < sources.length && !sources[i].isFound,
              onLookup: (number) async {
                if (number.trim().isEmpty) return;
                final entry = await flow.lookupBuyingSource(number);
                flow.replaceBuyingSource(i, entry);
              },
            ),
        DsNotice(
          icon: LucideIcons.info,
          message:
              'Your approval request goes to the first source only — '
              '$verifyingName. The others are recorded for Crown Solar\'s '
              'records.',
        ),
        DsButton(
          label: 'Add Another Source',
          variant: DsButtonVariant.secondary,
          icon: LucideIcons.plus,
          onPressed: flow == null
              ? () {}
              : () => setState(() => _requestedRows = rows + 1),
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
    this.number,
    this.matchedName,
    this.matchedMeta,
    this.verifies = false,
    this.controller,
    this.onLookup,
    this.notFound = false,
  });

  final int index;
  final String label;
  final String? number;
  final String? matchedName;
  final String? matchedMeta;
  final bool verifies;
  final TextEditingController? controller;
  final ValueChanged<String>? onLookup;
  final bool notFound;

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
          DsInput(
            label: 'Mobile number',
            value: controller == null ? number : null,
            controller: controller,
            keyboardType: TextInputType.phone,
            onChanged: onLookup == null ? null : (_) {},
            suffix: onLookup == null
                ? null
                : GestureDetector(
                    onTap: () => onLookup!(controller?.text ?? ''),
                    child: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: context.colors.primary,
                    ),
                  ),
          ),
          if (notFound) ...[
            const SizedBox(height: AppSpacing.stepMd),
            DsNotice(
              icon: LucideIcons.circleAlert,
              tone: DsTone.warning,
              message:
                  'No Crown Solar account found for this number. Check the '
                  'digits, or call the team if you are not sure who your '
                  'buying source is.',
              dense: true,
            ),
          ],
          if (matchedName == null && !notFound)
            const SizedBox.shrink()
          else if (matchedName != null) ...[
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
                          matchedName!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.status.success,
                          ),
                        ),
                        Text(
                          matchedMeta ?? 'found automatically',
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
