import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/profile_requests_service.dart';
import 'profile_request_detail_screen.dart';

/// New Profile — the buying source's side of a registration.
///
/// Someone applying to Crown Solar names where they buy from. This is the
/// list of those waiting on this partner; opening one shows everything the
/// applicant submitted and the two ways to answer.
///
/// The list stays deliberately thin. A buying source with several requests
/// is choosing which to deal with, not reading them all at once, and a
/// decision this final should be taken on a screen of its own.
class ProfileRequestsScreen extends StatefulWidget {
  const ProfileRequestsScreen({super.key});

  @override
  State<ProfileRequestsScreen> createState() => _ProfileRequestsScreenState();
}

class _ProfileRequestsScreenState extends State<ProfileRequestsScreen> {
  List<ProfileRequest>? _requests;
  List<ExpectedPurchase> _bands = const [];
  bool _reachable = true;

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
                      'Each of these named you as the partner they buy from. '
                      'Open one to see what they submitted and answer it.',
                ),
                const SizedBox(height: AppSpacing.stepMd),
                DsCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < requests.length; i++) ...[
                        DsSettingRow(
                          label: requests[i].businessName,
                          meta:
                              '${requests[i].reference} · '
                              '${requests[i].contactName}',
                          leading: DsAvatar(
                            initials: DsPartyRow.initialsOf(
                              requests[i].businessName,
                            ),
                          ),
                          trailing: DsTag(
                            label: requests[i].roleLabel,
                            tone: DsTone.info,
                          ),
                          onTap: () => _open(requests[i]),
                        ),
                        if (i != requests.length - 1) const DsHairline(),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(ProfileRequest request) async {
    final decided = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ProfileRequestDetailScreen(request: request, bands: _bands),
      ),
    );
    // Only a decision changes the list; coming back from a look does not.
    if (decided == true && mounted) await _load();
  }
}
