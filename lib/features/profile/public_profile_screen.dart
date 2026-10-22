import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import 'badge_pin.dart';
import 'badge_service.dart';
import 'catalog.dart';
import 'friends_repository.dart';
import 'profile_providers.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

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
              BadgePin(badge: badge, isEarned: isEarned, size: 80),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(publicProfileDocProvider(userId));
    final earnedBadgesAsync = ref.watch(publicProfileBadgesProvider(userId));

    final userDoc = userDocAsync.asData?.value;
    final avatarBgHex = userDoc?['avatarBgColor'] as String?;
    final avatarBgColorVal = avatarBgHex != null && avatarBgHex.startsWith('#')
        ? int.tryParse(avatarBgHex.replaceFirst('#', '0xFF'))
        : null;

    return GradientBackground.red(
      customColor: avatarBgColorVal != null ? Color(avatarBgColorVal) : null,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            userDocAsync.when(
              data: (userDoc) {
                if (userDoc == null) {
                  return const Center(child: Text('User profile not found.'));
                }

                final username = userDoc['username'] as String? ?? 'Captain';
                final avatarId = userDoc['avatarId'] as String?;
                final earnedMap = earnedBadgesAsync.asData?.value ?? {};

                int totalXp = 0;
                for (final badgeId in earnedMap.keys) {
                  final b = Catalog.getBadgeById(badgeId);
                  if (b != null) totalXp += b.xp;
                }

                final level = Catalog.getLevelFromXp(totalXp);
                final title = Catalog.getTitleFromLevel(level);

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      top: 88, left: 24, right: 24, bottom: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Captain Profile',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                          Text(
                            username,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$title • Level $level',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color:
                                      OceanThemeExtension.defaultTokens.cyan,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Consumer(
                            builder: (context, ref, _) {
                              final authUser = ref.watch(authStateProvider).asData?.value;
                              if (authUser == null || authUser.uid == userId) {
                                return const SizedBox.shrink();
                              }

                              final currentUserDoc = ref.watch(userDocStreamProvider).asData?.value;
                              final currentUsername = currentUserDoc?['username'] as String? ?? 'Captain';
                              final currentAvatarId = currentUserDoc?['avatarId'] as String?;
                              final currentAvatarBgColor = currentUserDoc?['avatarBgColor'] as String?;

                              final isFriendAsync = ref.watch(isFriendStreamProvider(userId));
                              final isFriend = isFriendAsync.asData?.value ?? false;

                              final requestStatusAsync = ref.watch(friendRequestStatusStreamProvider(userId));
                              final requestStatus = requestStatusAsync.asData?.value ?? FriendRequestStatus.none;

                              if (isFriend) {
                                return OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(
                                      color: Colors.white38,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final repo = ref.read(friendsRepositoryProvider);
                                    await repo.removeFriend(
                                      currentUid: authUser.uid,
                                      targetUid: userId,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Removed $username from friends.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.person_remove_outlined),
                                  label: const Text(
                                    'Remove Friend',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              }

                              if (requestStatus == FriendRequestStatus.sent) {
                                return OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(
                                      color: Colors.white38,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final repo = ref.read(friendsRepositoryProvider);
                                    await repo.cancelFriendRequest(
                                      currentUid: authUser.uid,
                                      targetUid: userId,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Cancelled friend request to $username.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.hourglass_top_outlined),
                                  label: const Text(
                                    'Request Sent (Cancel)',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              }

                              if (requestStatus == FriendRequestStatus.received) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: OceanThemeExtension.defaultTokens.cyan,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final repo = ref.read(friendsRepositoryProvider);
                                        await repo.approveFriendRequest(
                                          currentUid: authUser.uid,
                                          currentUsername: currentUsername,
                                          currentAvatarId: currentAvatarId,
                                          currentAvatarBgColor: currentAvatarBgColor,
                                          targetUid: userId,
                                          targetUsername: username,
                                          targetAvatarId: avatarId,
                                          targetAvatarBgColor: avatarBgHex,
                                        );
                                        final badgeResult = await ref
                                            .read(badgeServiceProvider)
                                            .onFriendAdded(userId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Accepted friend request from $username!'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          showBadgeUnlocks(context, badgeResult);
                                        }
                                      },
                                      icon: const Icon(Icons.check),
                                      label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                        side: const BorderSide(color: Colors.white38),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final repo = ref.read(friendsRepositoryProvider);
                                        await repo.denyFriendRequest(
                                          currentUid: authUser.uid,
                                          targetUid: userId,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Declined friend request from $username.'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.close),
                                      label: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              }

                              return OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: OceanThemeExtension.defaultTokens.cyan,
                                  side: BorderSide(
                                    color: OceanThemeExtension.defaultTokens.cyan,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: () async {
                                  final repo = ref.read(friendsRepositoryProvider);
                                  await repo.sendFriendRequest(
                                    currentUid: authUser.uid,
                                    currentUsername: currentUsername,
                                    currentAvatarId: currentAvatarId,
                                    currentAvatarBgColor: currentAvatarBgColor,
                                    targetUid: userId,
                                    targetUsername: username,
                                    targetAvatarId: avatarId,
                                    targetAvatarBgColor: avatarBgHex,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Friend request sent to $username!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.person_add_outlined),
                                label: const Text(
                                  'Add Friend',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 40, color: Colors.white30),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Earned Pins & Badges',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 110,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: Catalog.starterBadges.length,
                            itemBuilder: (context, index) {
                              final badge = Catalog.starterBadges[index];
                              final earnedAt = earnedMap[badge.id];
                              final isEarned = earnedAt != null;

                              return GestureDetector(
                                onTap: () => _showPinDetailDialog(
                                    context, badge, earnedAt),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BadgePin(
                                      badge: badge,
                                      isEarned: isEarned,
                                      size: 56,
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
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Error loading profile: $e')),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FloatingTopBar(isRedScreen: true),
            ),
          ],
        ),
      ),
    );
  }
}
