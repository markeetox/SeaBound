import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/gradient_background.dart';
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

    final earnedMap = earnedBadgesAsync.asData?.value ?? {};
    int totalXp = 0;
    for (final badgeId in earnedMap.keys) {
      final b = Catalog.getBadgeById(badgeId);
      if (b != null) totalXp += b.xp;
    }

    final level = Catalog.getLevelFromXp(totalXp);
    final title = Catalog.getTitleFromLevel(level);

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background Dashboard Overlay / Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF03112B).withValues(alpha: 0.85),
                      const Color(0xFF0B3A82).withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Main Centered Radial Dashboard Content
            Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 6 Radial Shortcut Buttons (3 on Left, 3 on Right)
                    // Left 1 (Upper Left)
                    Positioned(
                      left: 12,
                      top: 40,
                      child: _BlankRadialButton(label: 'Shortcut 1'),
                    ),
                    // Left 2 (Mid Left)
                    Positioned(
                      left: 0,
                      top: 150,
                      child: _BlankRadialButton(label: 'Shortcut 2'),
                    ),
                    // Left 3 (Lower Left)
                    Positioned(
                      left: 12,
                      bottom: 40,
                      child: _BlankRadialButton(label: 'Shortcut 3'),
                    ),

                    // Right 1 (Upper Right)
                    Positioned(
                      right: 12,
                      top: 40,
                      child: _BlankRadialButton(label: 'Shortcut 4'),
                    ),
                    // Right 2 (Mid Right)
                    Positioned(
                      right: 0,
                      top: 150,
                      child: _BlankRadialButton(label: 'Shortcut 5'),
                    ),
                    // Right 3 (Lower Right)
                    Positioned(
                      right: 12,
                      bottom: 40,
                      child: _BlankRadialButton(label: 'Shortcut 6'),
                    ),

                    // CENTER CIRCLE CONTAINER: Avatar, Name, Level in One Circle
                    ChromeBorderContainer(
                      borderRadius: BorderRadius.circular(110),
                      borderWidth: 3.5,
                      backgroundColor: const Color(0xFF0B2250),
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
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: OceanThemeExtension.defaultTokens.surface,
                              child: avatarId != null && avatarId.isNotEmpty
                                  ? Image.asset(
                                      'assets/avatars/$avatarId.png',
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.person,
                                        size: 46,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 46,
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
                        // SOS Spacer placeholder
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
      ),
    );
  }
}

class _BlankRadialButton extends StatelessWidget {
  final String label;

  const _BlankRadialButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return ChromeBorderContainer(
      borderRadius: BorderRadius.circular(30),
      borderWidth: 2.0,
      backgroundColor: const Color(0xFF0B2250),
      boxShadow: const [
        BoxShadow(
          color: Colors.black45,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OceanThemeExtension.defaultTokens.cyan.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
