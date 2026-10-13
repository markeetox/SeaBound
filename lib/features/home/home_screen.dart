import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/gradient_background.dart';
import '../alerts/alerts_providers.dart';
import '../profile/catalog.dart';
import '../profile/profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocStreamProvider);
    final earnedBadgesAsync = ref.watch(userEarnedBadgesProvider);

    final userDoc = userDocAsync.asData?.value;
    final username = userDoc?['username'] as String? ?? 'Captain';
    final avatarId = userDoc?['avatarId'] as String?;
    final avatarBgHex = userDoc?['avatarBgColor'] as String?;
    final avatarBgColorVal = avatarBgHex != null && avatarBgHex.startsWith('#')
        ? int.tryParse(avatarBgHex.replaceFirst('#', '0xFF'))
        : null;
    final avatarBgColor = avatarBgColorVal != null
        ? Color(avatarBgColorVal)
        : OceanThemeExtension.defaultTokens.surface;

    final earnedMap = earnedBadgesAsync.asData?.value ?? {};
    int totalXp = 0;
    for (final badgeId in earnedMap.keys) {
      final b = Catalog.getBadgeById(badgeId);
      if (b != null) totalXp += b.xp;
    }

    final level = Catalog.getLevelFromXp(totalXp);
    final title = Catalog.getTitleFromLevel(level);

    return Scaffold(
      backgroundColor: const Color(0xFF03112B),
      body: Stack(
        children: [
          // Background Image with Fallback Gradient
          Positioned.fill(
            child: Image.asset(
              'assets/ui/home_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const GradientBackground.blue(child: SizedBox.expand());
              },
            ),
          ),

          // Dark Overlay for Contrast & Readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),

          // Top Weather Information & Local Alerts Banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: const _TopWeatherAndAlertsBanner(),
            ),
          ),

          // Left 3 Side Edge Tabs (vertically centered alongside center circle)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SideEdgeTab(
                    side: SideEdge.left,
                    label: 'Trips',
                    icon: Icons.explore_outlined,
                    onTap: () => context.go('/trips'),
                  ),
                  const SizedBox(height: 24),
                  _SideEdgeTab(
                    side: SideEdge.left,
                    label: 'Spots',
                    icon: Icons.place_outlined,
                    isNarrow: true,
                    onTap: () => context.go('/spots'),
                  ),
                  const SizedBox(height: 24),
                  _SideEdgeTab(
                    side: SideEdge.left,
                    label: 'Alerts',
                    icon: Icons.notifications_outlined,
                    onTap: () => context.go('/alerts'),
                  ),
                ],
              ),
            ),
          ),

          // Right 3 Side Edge Tabs (vertically centered alongside center circle)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SideEdgeTab(
                    side: SideEdge.right,
                    label: 'Profile',
                    icon: Icons.person_outlined,
                    onTap: () => context.go('/profile'),
                  ),
                  const SizedBox(height: 24),
                  _SideEdgeTab(
                    side: SideEdge.right,
                    label: 'Weather',
                    icon: Icons.wb_sunny_outlined,
                    isNarrow: true,
                    onTap: () => context.go('/spots'),
                  ),
                  const SizedBox(height: 24),
                  _SideEdgeTab(
                    side: SideEdge.right,
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    onTap: () => context.push('/profile/edit'),
                  ),
                ],
              ),
            ),
          ),

          // CENTER CIRCLE CONTAINER: Avatar, Name, Level (Tap to open Profile)
          Center(
            child: GestureDetector(
              onTap: () {
                context.go('/profile');
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ChromeBorderContainer(
                  borderRadius: BorderRadius.circular(110),
                  borderWidth: 3.5,
                  backgroundColor: Color.alphaBlend(
                    Colors.black.withValues(alpha: 0.40),
                    avatarBgColor,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: Offset(0, 6),
                    ),
                  ],
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // User Avatar
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: avatarId != null && avatarId.isNotEmpty
                              ? Image.asset(
                                  'assets/avatars/$avatarId.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 56,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(height: 8),
                        // User Username
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // User Level & Title
                        Text(
                          '$title • Lvl $level',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: OceanThemeExtension.defaultTokens.cyan,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Red SOS Spacer Button at Bottom-Left of Screen
          Positioned(
            bottom: 24,
            left: 16,
            child: SafeArea(
              child: ChromeBorderContainer(
                borderRadius: BorderRadius.circular(28),
                borderWidth: 2.5,
                backgroundColor: const Color(0xFFD1142A),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SOS Emergency feature coming soon.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(26),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 6),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopWeatherAndAlertsBanner extends ConsumerWidget {
  const _TopWeatherAndAlertsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsNotifierProvider);
    final alerts = alertsState.alerts;

    String alertText;
    IconData alertIcon;
    Color alertColor;

    if (alerts.isNotEmpty) {
      final topAlert = alerts.first;
      alertText = topAlert.event;
      alertIcon = Icons.warning_rounded;
      alertColor = const Color(0xFFFFB74D); // Amber
    } else if (alertsState.isOutOfCoverage) {
      alertText = 'Outside NWS Marine Coverage';
      alertIcon = Icons.info_outline_rounded;
      alertColor = Colors.white70;
    } else if (alertsState.errorMessage != null) {
      alertText = 'Alert Status Unavailable';
      alertIcon = Icons.error_outline_rounded;
      alertColor = const Color(0xFFFFB74D);
    } else {
      alertText = 'No Active Local Marine Alerts';
      alertIcon = Icons.check_circle_outline_rounded;
      alertColor = OceanThemeExtension.defaultTokens.cyan;
    }

    return ChromeBorderContainer(
      borderRadius: BorderRadius.circular(20),
      borderWidth: 2.0,
      backgroundColor: const Color(0xFF03112B).withValues(alpha: 0.85),
      boxShadow: const [
        BoxShadow(
          color: Colors.black45,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Weather Icon & Temp
            const Icon(
              Icons.wb_sunny_rounded,
              color: Color(0xFFFFD54F),
              size: 26,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '78°F Sunny',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Wind: 12 kts E',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Divider
            Container(
              height: 28,
              width: 1,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            // Local Alert Status
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(alertIcon, color: alertColor, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      alertText,
                      style: TextStyle(
                        color: alertColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SideEdge { left, right }

class _SideEdgeTab extends StatelessWidget {
  final SideEdge side;
  final String label;
  final IconData icon;
  final bool isNarrow;
  final VoidCallback onTap;

  const _SideEdgeTab({
    required this.side,
    required this.label,
    required this.icon,
    this.isNarrow = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = side == SideEdge.left;
    final hPadding = isNarrow ? 8.0 : 16.0;
    const vPadding = 18.0;

    return ChromeBorderContainer(
      borderRadius: BorderRadius.only(
        topRight: isLeft ? const Radius.circular(20) : Radius.zero,
        bottomRight: isLeft ? const Radius.circular(20) : Radius.zero,
        topLeft: !isLeft ? const Radius.circular(20) : Radius.zero,
        bottomLeft: !isLeft ? const Radius.circular(20) : Radius.zero,
      ),
      borderWidth: 2.0,
      backgroundColor: const Color(0xFF0B2250).withValues(alpha: 0.90),
      boxShadow: const [
        BoxShadow(
          color: Colors.black45,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.only(
            topRight: isLeft ? const Radius.circular(18) : Radius.zero,
            bottomRight: isLeft ? const Radius.circular(18) : Radius.zero,
            topLeft: !isLeft ? const Radius.circular(18) : Radius.zero,
            bottomLeft: !isLeft ? const Radius.circular(18) : Radius.zero,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: isLeft
                  ? [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: isNarrow ? 4 : 8),
                      Icon(icon, color: OceanThemeExtension.defaultTokens.cyan, size: 20),
                    ]
                  : [
                      Icon(icon, color: OceanThemeExtension.defaultTokens.cyan, size: 20),
                      SizedBox(width: isNarrow ? 4 : 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
