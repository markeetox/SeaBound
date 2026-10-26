import 'package:cloud_firestore/cloud_firestore.dart';

import 'catalog.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<Map<String, dynamic>?> getUserDocStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return snap.data();
      }
      return null;
    });
  }

  Stream<Map<String, DateTime>> getUserEarnedBadgesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('badges')
        .snapshots()
        .map((snap) {
      final map = <String, DateTime>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final ts = data['earnedAt'] as Timestamp?;
        map[doc.id] = ts?.toDate() ?? DateTime.now();
      }
      return map;
    });
  }

  Future<void> removeEmailFromUserDoc(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('email')) {
      await userRef.update({
        'email': FieldValue.delete(),
      });
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String username,
    required String avatarId,
    String? avatarBgColor,
  }) async {
    final validationErr = Catalog.validateUsername(username);
    if (validationErr != null) {
      throw Exception(validationErr);
    }

    final newUsernameLower = username.trim().toLowerCase();

    // Perform atomic transaction to claim username and release old username if changed
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(uid);
      final userSnap = await transaction.get(userRef);

      String? oldUsernameLower;
      if (userSnap.exists && userSnap.data() != null) {
        oldUsernameLower = userSnap.data()!['usernameLower'] as String?;
      }

      final isChangingUsername = oldUsernameLower != newUsernameLower;

      if (isChangingUsername) {
        final newUsernameRef =
            _firestore.collection('usernames').doc(newUsernameLower);
        final newUsernameSnap = await transaction.get(newUsernameRef);

        if (newUsernameSnap.exists) {
          final claimedUid = newUsernameSnap.data()?['uid'] as String?;
          if (claimedUid != uid) {
            throw Exception('Username "$username" is already taken.');
          }
        }

        // Claim new username
        transaction.set(newUsernameRef, {'uid': uid});

        // Release old username if it existed
        if (oldUsernameLower != null && oldUsernameLower.isNotEmpty) {
          final oldUsernameRef =
              _firestore.collection('usernames').doc(oldUsernameLower);
          transaction.delete(oldUsernameRef);
        }
      }

      // Update user document (ensuring no email field is written)
      transaction.set(
        userRef,
        {
          'username': username.trim(),
          'usernameLower': newUsernameLower,
          'avatarId': avatarId,
          'avatarBgColor': ?avatarBgColor,
          'createdAt': userSnap.exists && userSnap.data()?['createdAt'] != null
              ? userSnap.data()!['createdAt']
              : FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<int> getUserTripCount(String uid) async {
    final snap = await _firestore
        .collection('trips')
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> getUserSpotCount(String uid) async {
    final snap = await _firestore
        .collection('spots')
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<List<Map<String, dynamic>>> searchCaptains(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final snap = await _firestore
        .collection('users')
        .where('usernameLower', isGreaterThanOrEqualTo: clean)
        .where('usernameLower', isLessThanOrEqualTo: '$clean\uf8ff')
        .limit(10)
        .get();

    return snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
  }
}
