import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import '../spots/spots_providers.dart';
import '../trips/trips_providers.dart';
import 'badge_pin.dart';
import 'badge_service.dart';
import 'catalog.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProfileOnOpen();
    });
  }

  Future<void> _initProfileOnOpen() async {
    final authState = ref.read(authStateProvider);
    final user = authState.asData?.value;
    if (user != null) {
      final repository = ref.read(profileRepositoryProvider);
      await repository.removeEmailFromUserDoc(user.uid);

      final badgeService = ref.read(badgeServiceProvider);
      final result = await badgeService.checkAllBadges();

      if (mounted) {
        showBadgeUnlocks(context, result);
      }
    }
  }

  void _showPinDetailDialog(BuildContext context, AchievementBadge badge, DateTime? earnedAt) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isEarned = earnedAt != null;
        final formattedDate =
            isEarned ? DateFormat.yMMMMd().format(earnedAt) : null;

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgePin(badge: badge, isEarned: isEarned, size: 120),
              const SizedBox(height: 12),
              Text(
                badge.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isEarned ? badge.description : badge.hint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Chip(
                label: Text('+${badge.xp} XP',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: OceanThemeExtension.defaultTokens.surface,
              ),
              if (isEarned && formattedDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Earned on $formattedDate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ],
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
    final authState = ref.watch(authStateProvider);
    final userDocState = ref.watch(userDocStreamProvider);
    final earnedBadgesState = ref.watch(userEarnedBadgesProvider);
    final tripsAsync = ref.watch(userTripsStreamProvider);
    final spotsAsync = ref.watch(allSpotsStreamProvider);

    final currentUser = authState.asData?.value;
    final userDoc = userDocState.asData?.value;
    final earnedMap = earnedBadgesState.asData?.value ?? {};

    final username = userDoc?['username'] as String? ??
        currentUser?.displayName ??
        'Captain';
    final avatarId = userDoc?['avatarId'] as String?;
    final avatarBgHex = userDoc?['avatarBgColor'] as String?;
    final avatarBgColorVal = avatarBgHex != null && avatarBgHex.startsWith('#')
        ? int.tryParse(avatarBgHex.replaceFirst('#', '0xFF'))
        : null;

    int totalXp = 0;
    for (final badgeId in earnedMap.keys) {
      final b = Catalog.getBadgeById(badgeId);
      if (b != null) totalXp += b.xp;
    }

    final level = Catalog.getLevelFromXp(totalXp);
    final title = Catalog.getTitleFromLevel(level);

    final currentLevelXp = Catalog.xpForLevel(level);
    final nextLevelXp = Catalog.xpForLevel(level + 1);
    final levelXpProgress = totalXp - currentLevelXp;
    final levelXpNeeded = nextLevelXp - currentLevelXp;
    final progressFraction =
        levelXpNeeded > 0 ? (levelXpProgress / levelXpNeeded).clamp(0.0, 1.0) : 1.0;

    final tripCount = tripsAsync.asData?.value.length ?? 0;
    final spotCount = spotsAsync.asData?.value
            .where((s) => s.userId == currentUser?.uid)
            .length ??
        0;

    return GradientBackground.red(
      customColor: avatarBgColorVal != null ? Color(avatarBgColorVal) : null,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 88, left: 24, right: 24, bottom: 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // Profile Info
                      SizedBox(
                        width: 125,
                        height: 125,
                        child: avatarId != null && avatarId.isNotEmpty
                            ? Image.asset(
                                'assets/avatars/$avatarId.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 72,
                                    color: Colors.white,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                size: 72,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Username 36 w900
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$title • Level $level',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: OceanThemeExtension.defaultTokens.cyan,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // XP Progress Bar with Dark Outline
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level $level Progress',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$totalXp / $nextLevelXp XP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.8), width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progressFraction,
                                minHeight: 12,
                                backgroundColor: Colors.black45,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  OceanThemeExtension.defaultTokens.cyan,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Section on Solid Black (#000000) rounded container with 2px white border
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CircleStatTile(label: 'Trips', value: '$tripCount'),
                            _CircleStatTile(label: 'Spots', value: '$spotCount'),
                            _CircleStatTile(label: 'Pins', value: '${earnedMap.length}'),
                          ],
                        ),
                      ),
                      const Divider(height: 40, color: Colors.white30),

                      // Pins Grid Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Earned Pins & Badges',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 130,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.80,
                        ),
                        itemCount: Catalog.starterBadges.length,
                        itemBuilder: (context, index) {
                          final badge = Catalog.starterBadges[index];
                          final earnedAt = earnedMap[badge.id];
                          final isEarned = earnedAt != null;

                          return GestureDetector(
                            onTap: () => _showPinDetailDialog(context, badge, earnedAt),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BadgePin(
                                  badge: badge,
                                  isEarned: isEarned,
                                  size: 84,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  badge.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isEarned
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isEarned
                                        ? Colors.white
                                        : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Floating Top Bar Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FloatingTopBar(
                isRedScreen: true,
                actions: [
                  FloatingTopBarButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit Profile',
                    isRedScreen: true,
                    onPressed: () {
                      context.push('/profile/edit');
                    },
                  ),
                  FloatingTopBarButton(
                    icon: Icons.info_outline,
                    tooltip: 'About & Data Sources',
                    isRedScreen: true,
                    onPressed: () {
                      context.push('/about');
                    },
                  ),
                  FloatingTopBarButton(
                    icon: Icons.logout,
                    tooltip: 'Sign Out',
                    isRedScreen: true,
                    onPressed: () async {
                      final authRepo = ref.read(authRepositoryProvider);
                      await authRepo.signOut();
                    },
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

class _CircleStatTile extends StatelessWidget {
  final String label;
  final String value;

  const _CircleStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: ChromeBorder.gradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: OceanThemeExtension.defaultTokens.surface,
              ),
              child: Center(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
