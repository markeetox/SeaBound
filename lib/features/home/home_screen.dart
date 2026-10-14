import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/gradient_background.dart';
import '../../core/map_layer_config.dart';
import '../alerts/alerts_providers.dart';
import '../map_layers/map_layers_provider.dart';
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

          // CENTER AVATAR CIRCLE & RADIAL ROUND BUTTONS
          Center(
            child: SizedBox(
              width: 360,
              height: 360,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // CENTER CIRCLE CONTAINER: Avatar, Name, Level (Tap to open Profile)
                  GestureDetector(
                    onTap: () {
                      context.go('/profile');
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ChromeBorderContainer(
                        borderRadius: BorderRadius.circular(90),
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
                          width: 160,
                          height: 160,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // User Avatar
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: avatarId != null && avatarId.isNotEmpty
                                    ? Image.asset(
                                        'assets/avatars/$avatarId.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person,
                                          size: 44,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 44,
                                        color: Colors.white,
                                      ),
                              ),
                              const SizedBox(height: 4),
                              // User Username
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 16,
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
                                  fontSize: 11,
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

                  // Top Left: Fish locations (82px, greyed out coming soon feature)
                  Positioned(
                    left: 14,
                    top: 24,
                    child: _RadialRoundButton(
                      label: 'Fish locations',
                      icon: Icons.phishing,
                      size: 82,
                      isComingSoon: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fish locations feature coming soon.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),

                  // Middle Left: Waves (82px, map with only waves filter active)
                  Positioned(
                    left: 1,
                    top: 139,
                    child: _RadialRoundButton(
                      label: 'Waves',
                      icon: Icons.tsunami,
                      size: 82,
                      onTap: () {
                        ref.read(activeMapLayersProvider.notifier).setLayers({
                          MapLayerConfig.wavesId,
                        });
                        context.go('/spots');
                      },
                    ),
                  ),

                  // Bottom Left: Depth (82px, map with only depth filter active)
                  Positioned(
                    left: 14,
                    top: 254,
                    child: _RadialRoundButton(
                      label: 'Depth',
                      icon: Icons.water,
                      size: 82,
                      onTap: () {
                        ref.read(activeMapLayersProvider.notifier).setLayers({
                          MapLayerConfig.depthBathymetryId,
                        });
                        context.go('/spots');
                      },
                    ),
                  ),

                  // Top Right: Trips (82px)
                  Positioned(
                    right: 14,
                    top: 24,
                    child: _RadialRoundButton(
                      label: 'Trips',
                      icon: Icons.explore_outlined,
                      size: 82,
                      onTap: () => context.go('/trips'),
                    ),
                  ),

                  // Middle Right: Alerts (82px)
                  Positioned(
                    right: 1,
                    top: 139,
                    child: _RadialRoundButton(
                      label: 'Alerts',
                      icon: Icons.notifications_outlined,
                      size: 82,
                      onTap: () => context.go('/alerts'),
                    ),
                  ),

                  // Bottom Right: Spots (82px)
                  Positioned(
                    right: 14,
                    top: 254,
                    child: _RadialRoundButton(
                      label: 'Spots',
                      icon: Icons.place_outlined,
                      size: 82,
                      onTap: () => context.go('/spots'),
                    ),
                  ),
                ],
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Weather Information (Stacked Top - Twice as big)
            Row(
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFFFD54F),
                  size: 68,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '78°F Sunny',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Wind: 14 mph E',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Local Alert Banner (Stacked Underneath - Tappable to navigate to Alerts)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/alerts'),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(alertIcon, color: alertColor, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alertText,
                        style: TextStyle(
                          color: alertColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: alertColor.withValues(alpha: 0.8),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadialRoundButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double size;
  final bool isComingSoon;
  final VoidCallback onTap;

  const _RadialRoundButton({
    required this.label,
    required this.icon,
    this.size = 82.0,
    this.isComingSoon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isComingSoon
        ? Colors.white38
        : OceanThemeExtension.defaultTokens.cyan;
    final textColor = isComingSoon
        ? Colors.white38
        : Colors.white;
    final bgColor = isComingSoon
        ? const Color(0xFF0B2250).withValues(alpha: 0.50)
        : const Color(0xFF0B2250).withValues(alpha: 0.90);

    return ChromeBorderContainer(
      borderRadius: BorderRadius.circular(size / 2),
      borderWidth: 2.5,
      backgroundColor: bgColor,
      boxShadow: [
        BoxShadow(
          color: isComingSoon ? Colors.black26 : Colors.black45,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
