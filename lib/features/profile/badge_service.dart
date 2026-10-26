import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'badge_pin.dart';
import 'catalog.dart';

class BadgeResult {
  final List<AchievementBadge> unlockedBadges;
  final int oldLevel;
  final int newLevel;

  bool get isLevelUp => newLevel > oldLevel;

  const BadgeResult({
    this.unlockedBadges = const [],
    this.oldLevel = 1,
    this.newLevel = 1,
  });
}

void showBadgeUnlocks(BuildContext context, BadgeResult result) {
  if (result.unlockedBadges.isEmpty) return;

  for (final badge in result.unlockedBadges) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('🎉 Badge Unlocked!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgePin(badge: badge, isEarned: true, size: 160),
              const SizedBox(height: 12),
              Text(
                badge.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text('+${badge.xp} XP'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              if (result.isLevelUp) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⭐ Level Up! You reached Level ${result.newLevel} (${Catalog.getTitleFromLevel(result.newLevel)})!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Awesome!'),
            ),
          ],
        );
      },
    );
  }
}

class BadgeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BadgeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  static const markeetoxUid = 'ojMSrDiSHHZs82kwFGVADnvQGCh1';
  static const osnola26Uid = 'XAabc7h3qLXw0xMhFwBR9dDYeuD2';

  Future<BadgeResult> checkAllBadges() async {
    if (_user == null) return const BadgeResult();
    final uid = _user!.uid;

    final unlocked = <AchievementBadge>[];

    // Check welcome and founding crew
    unlocked.addAll(await _checkWelcomeAndFoundingCrew(uid));

    // Check trip badges
    unlocked.addAll(await _checkTripBadges(uid));

    // Check spot badges
    unlocked.addAll(await _checkSpotBadges(uid));

    // Check profile colors_raised
    unlocked.addAll(await _checkProfileColorsRaised(uid));

    // Check friend badges
    unlocked.addAll(await _checkFriendBadges(uid));

    return _buildResultAndSetBadges(uid, unlocked);
  }

  Future<BadgeResult> onFriendAdded(String targetUid) async {
    if (_user == null) return const BadgeResult();
    final uid = _user!.uid;
    final unlocked = <AchievementBadge>[];

    if (targetUid == markeetoxUid) {
      final b = await _awardBadge(uid, 'friend_markeetox');
      if (b != null) unlocked.add(b);
    } else if (targetUid == osnola26Uid) {
      final b = await _awardBadge(uid, 'friend_osnola26');
      if (b != null) unlocked.add(b);
    }

    return _buildResultAndSetBadges(uid, unlocked);
  }

  Future<List<AchievementBadge>> _checkFriendBadges(String uid) async {
    final list = <AchievementBadge>[];

    final markeetoxDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(markeetoxUid)
        .get();
    if (markeetoxDoc.exists) {
      final b = await _awardBadge(uid, 'friend_markeetox');
      if (b != null) list.add(b);
    }

    final osnolaDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(osnola26Uid)
        .get();
    if (osnolaDoc.exists) {
      final b = await _awardBadge(uid, 'friend_osnola26');
      if (b != null) list.add(b);
    }

    return list;
  }

  Future<BadgeResult> onTripLogged(String uid, int tripCount) async {
    final toAward = <String>[];
    if (tripCount >= 1) toAward.add('first_log');
    if (tripCount >= 5) toAward.add('regular');
    if (tripCount >= 25) toAward.add('salty_dog');

    final unlocked = <AchievementBadge>[];
    for (final badgeId in toAward) {
      final b = await _awardBadge(uid, badgeId);
      if (b != null) unlocked.add(b);
    }

    return _buildResultAndSetBadges(uid, unlocked);
  }

  Future<BadgeResult> onSpotShared(String uid, int spotCount) async {
    final unlocked = <AchievementBadge>[];
    if (spotCount >= 1) {
      final b = await _awardBadge(uid, 'spot_finder');
      if (b != null) unlocked.add(b);
    }
    return _buildResultAndSetBadges(uid, unlocked);
  }

  Future<BadgeResult> onDepthLayerToggled() async {
    if (_user == null) return const BadgeResult();
    final unlocked = <AchievementBadge>[];
    final b = await _awardBadge(_user!.uid, 'chart_reader');
    if (b != null) unlocked.add(b);
    return _buildResultAndSetBadges(_user!.uid, unlocked);
  }

  Future<BadgeResult> onAlertsOpened() async {
    if (_user == null) return const BadgeResult();
    final unlocked = <AchievementBadge>[];
    final b = await _awardBadge(_user!.uid, 'weather_eye');
    if (b != null) unlocked.add(b);
    return _buildResultAndSetBadges(_user!.uid, unlocked);
  }

  Future<BadgeResult> onMyLocationTapped() async {
    if (_user == null) return const BadgeResult();
    final unlocked = <AchievementBadge>[];
    final b = await _awardBadge(_user!.uid, 'navigator');
    if (b != null) unlocked.add(b);
    return _buildResultAndSetBadges(_user!.uid, unlocked);
  }

  Future<BadgeResult> onProfileUpdated() async {
    if (_user == null) return const BadgeResult();
    final unlocked = await _checkProfileColorsRaised(_user!.uid);
    return _buildResultAndSetBadges(_user!.uid, unlocked);
  }

  Future<List<AchievementBadge>> _checkWelcomeAndFoundingCrew(String uid) async {
    final list = <AchievementBadge>[];
    final w = await _awardBadge(uid, 'welcome_aboard');
    if (w != null) list.add(w);

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final createdAtTS = userDoc.data()?['createdAt'] as Timestamp?;
    final createdAt = createdAtTS?.toDate() ?? DateTime.now();

    if (createdAt.isBefore(Catalog.foundingCrewCutoff)) {
      final f = await _awardBadge(uid, 'founding_crew');
      if (f != null) list.add(f);
    }
    return list;
  }

  Future<List<AchievementBadge>> _checkTripBadges(String uid) async {
    final countQuery = await _firestore
        .collection('trips')
        .where('userId', isEqualTo: uid)
        .count()
        .get();

    final tripCount = countQuery.count ?? 0;
    final res = await onTripLogged(uid, tripCount);
    return res.unlockedBadges;
  }

  Future<List<AchievementBadge>> _checkSpotBadges(String uid) async {
    final countQuery = await _firestore
        .collection('spots')
        .where('userId', isEqualTo: uid)
        .count()
        .get();

    final spotCount = countQuery.count ?? 0;
    final res = await onSpotShared(uid, spotCount);
    return res.unlockedBadges;
  }

  Future<List<AchievementBadge>> _checkProfileColorsRaised(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    final username = data?['username'] as String?;
    final avatarId = data?['avatarId'] as String?;

    if (username != null &&
        username.isNotEmpty &&
        avatarId != null &&
        avatarId.isNotEmpty) {
      final b = await _awardBadge(uid, 'colors_raised');
      if (b != null) return [b];
    }
    return [];
  }

  Future<AchievementBadge?> _awardBadge(String uid, String badgeId) async {
    final badge = Catalog.getBadgeById(badgeId);
    if (badge == null) return null;

    final badgeDocRef =
        _firestore.collection('users').doc(uid).collection('badges').doc(badgeId);

    final badgeDoc = await badgeDocRef.get();
    if (badgeDoc.exists) return null; // Already awarded

    await badgeDocRef.set({
      'earnedAt': FieldValue.serverTimestamp(),
    });

    return badge;
  }

  Future<BadgeResult> _buildResultAndSetBadges(
    String uid,
    List<AchievementBadge> newUnlocked,
  ) async {
    if (newUnlocked.isEmpty) {
      return const BadgeResult();
    }

    final existingBadgesSnap =
        await _firestore.collection('users').doc(uid).collection('badges').get();

    int totalXp = 0;
    for (final doc in existingBadgesSnap.docs) {
      final b = Catalog.getBadgeById(doc.id);
      if (b != null) totalXp += b.xp;
    }

    int newlyUnlockedXp = 0;
    for (final b in newUnlocked) {
      newlyUnlockedXp += b.xp;
    }

    final oldTotalXp = (totalXp - newlyUnlockedXp).clamp(0, 999999);
    final oldLevel = Catalog.getLevelFromXp(oldTotalXp);
    final newLevel = Catalog.getLevelFromXp(totalXp);

    return BadgeResult(
      unlockedBadges: newUnlocked,
      oldLevel: oldLevel,
      newLevel: newLevel,
    );
  }
}

final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService();
});
