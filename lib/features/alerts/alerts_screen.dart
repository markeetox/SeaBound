import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import '../map/location_providers.dart';
import '../profile/badge_service.dart';
import '../profile/profile_providers.dart';
import 'alerts_providers.dart';
import 'weather_alert_model.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await ref.read(badgeServiceProvider).onAlertsOpened();
      if (!mounted) return;
      showBadgeUnlocks(context, result);
    });
  }

  void _showAlertDetail(BuildContext context, WeatherAlert alert) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alert.event,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              _SeverityChip(severity: alert.severity),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (alert.areaDesc.isNotEmpty) ...[
                  Text(
                    'Affected Area:',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(alert.areaDesc),
                  const SizedBox(height: 12),
                ],
                if (alert.headline.isNotEmpty) ...[
                  Text(
                    alert.headline,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (alert.description.isNotEmpty) ...[
                  Text(
                    'Description:',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(alert.description),
                  const SizedBox(height: 12),
                ],
                if (alert.instruction.isNotEmpty) ...[
                  Text(
                    'Instructions:',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(alert.instruction),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Sender: ${alert.senderName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsNotifierProvider);
    final alertsNotifier = ref.read(alertsNotifierProvider.notifier);
    final incomingRequestsAsync = ref.watch(incomingFriendRequestsStreamProvider);
    final incomingRequests = incomingRequestsAsync.asData?.value ?? [];

    ref.listen<AsyncValue<Position>>(userPositionStreamProvider, (prev, next) {
      if (next.hasValue) {
        alertsNotifier.onPositionUpdate(next.value!);
      }
    });

    final lastCheckedStr = alertsState.lastChecked != null
        ? DateFormat.jm().format(alertsState.lastChecked!)
        : null;

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 88, bottom: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Incoming Friend Requests Section
                        if (incomingRequests.isNotEmpty) ...[
                          Text(
                            'Friend Requests (${incomingRequests.length})',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: OceanThemeExtension.defaultTokens.cyan,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: incomingRequests.length,
                            itemBuilder: (context, index) {
                              final req = incomingRequests[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: OceanThemeExtension.defaultTokens.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: req.fromAvatarId != null && req.fromAvatarId!.isNotEmpty
                                            ? Image.asset(
                                                'assets/avatars/${req.fromAvatarId}.png',
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                                              )
                                            : const Icon(Icons.person, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              req.fromUsername,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const Text(
                                              'Sent you a friend request',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Accept',
                                            icon: const Icon(Icons.check_circle, color: Colors.green),
                                            onPressed: () async {
                                              final authUser = ref.read(authStateProvider).asData?.value;
                                              if (authUser == null) return;
                                              final userDoc = ref.read(userDocStreamProvider).asData?.value;
                                              final myUsername = userDoc?['username'] as String? ?? 'Captain';
                                              final myAvatarId = userDoc?['avatarId'] as String?;
                                              final myAvatarBg = userDoc?['avatarBgColor'] as String?;

                                              final repo = ref.read(friendsRepositoryProvider);
                                              await repo.approveFriendRequest(
                                                currentUid: authUser.uid,
                                                currentUsername: myUsername,
                                                currentAvatarId: myAvatarId,
                                                currentAvatarBgColor: myAvatarBg,
                                                targetUid: req.fromUid,
                                                targetUsername: req.fromUsername,
                                                targetAvatarId: req.fromAvatarId,
                                                targetAvatarBgColor: req.fromAvatarBgColor,
                                              );
                                              final badgeResult = await ref
                                                  .read(badgeServiceProvider)
                                                  .onFriendAdded(req.fromUid);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Accepted request from ${req.fromUsername}!'),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                                showBadgeUnlocks(context, badgeResult);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Decline',
                                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                            onPressed: () async {
                                              final authUser = ref.read(authStateProvider).asData?.value;
                                              if (authUser == null) return;
                                              final repo = ref.read(friendsRepositoryProvider);
                                              await repo.denyFriendRequest(
                                                currentUid: authUser.uid,
                                                targetUid: req.fromUid,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Declined request from ${req.fromUsername}.'),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 32, color: Colors.white24),
                        ],

                        Text(
                          'Weather & Marine Alerts',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 16),

                        // Header status / timestamp bar
                        if (lastCheckedStr != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            decoration: BoxDecoration(
                              color: OceanThemeExtension.defaultTokens.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Last checked $lastCheckedStr',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                if (alertsState.isLoading)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),
                        _buildBodyContent(context, alertsState, lastCheckedStr),
                        const SizedBox(height: 24),

                        // Mandatory Footer Disclaimer
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: OceanThemeExtension.defaultTokens.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: Text(
                            'Alerts are checked only while Seabound is open and may be delayed. Always check weather.gov and VHF marine radio for official warnings.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Top Bar with Refresh Action
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FloatingTopBar(
                actions: [
                  FloatingTopBarButton(
                    icon: Icons.refresh,
                    tooltip: 'Refresh Alerts',
                    onPressed: alertsState.isLoading
                        ? null
                        : () => alertsNotifier.refreshAlerts(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    AlertsState state,
    String? lastCheckedStr,
  ) {
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isOutOfCoverage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.public_off,
                size: 64,
                color: Colors.white60,
              ),
              const SizedBox(height: 16),
              Text(
                'Active weather alerts are unavailable for this point.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'National Weather Service active alert coverage is limited to US coastal and inland areas.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 64,
                color: OceanThemeExtension.defaultTokens.cyan,
              ),
              const SizedBox(height: 16),
              Text(
                lastCheckedStr != null
                    ? 'No active alerts for this location as of $lastCheckedStr.'
                    : 'No active weather alerts for this location.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.alerts.length,
      itemBuilder: (context, index) {
        final alert = state.alerts[index];
        final effectiveStr = alert.effective != null
            ? DateFormat.jm().format(alert.effective!)
            : null;
        final expiresStr = alert.expires != null
            ? DateFormat.jm().format(alert.expires!)
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAlertDetail(context, alert),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (alert.isMarineRelated) ...[
                              Icon(
                                Icons.phishing,
                                size: 20,
                                color: OceanThemeExtension.defaultTokens.cyan,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                alert.event,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SeverityChip(severity: alert.severity),
                    ],
                  ),
                  if (alert.areaDesc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alert.areaDesc,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (effectiveStr != null || expiresStr != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Valid: ${effectiveStr ?? 'Now'} – ${expiresStr ?? 'Until further notice'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String severity;

  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;

    switch (severity.toLowerCase()) {
      case 'extreme':
        backgroundColor = Colors.red.shade900;
        break;
      case 'severe':
        backgroundColor = Colors.red.shade700;
        break;
      case 'moderate':
        backgroundColor = Colors.orange.shade800;
        break;
      case 'minor':
        backgroundColor = Colors.amber.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
