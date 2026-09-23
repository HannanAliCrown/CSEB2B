import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/profile_requests_service.dart';

/// New Profile — the buying source's inbox.
///
/// Someone applying to Crown Solar names where they buy from. This lists
/// who is waiting on this partner; opening one is where the verdict is
/// given, so the list stays scannable however much an application contains.
class ProfileRequestsScreen extends StatefulWidget {
  const ProfileRequestsScreen({super.key, required this.onOpenRequest});

  final Future<void> Function(String applicationId) onOpenRequest;

  @override
  State<ProfileRequestsScreen> createState() => _ProfileRequestsScreenState();
}

class _ProfileRequestsScreenState extends State<ProfileRequestsScreen> {
  List<ProfileRequest>? _requests;
  bool _reachable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    final loaded = await context.read<ProfileRequestsService>().pending(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() {
      _requests = loaded ?? const [];
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
                    onTap: () async {
                      await widget.onOpenRequest(request.applicationId);
                      await _load();
                    },
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
}

/// One waiting request, as much of it as picking between them needs.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final ProfileRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          DsCaption(
            // Read left to right in every language: a number regrouped by a
            // right-to-left run is a different number.
            '${request.contactName} · ‎+92 ${request.mobileNumber}‎',
          ),
        ],
      ),
    );
  }
}
