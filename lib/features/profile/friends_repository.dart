import 'package:cloud_firestore/cloud_firestore.dart';

class FriendInfo {
  final String uid;
  final String username;
  final String? avatarId;
  final String? avatarBgColor;

  const FriendInfo({
    required this.uid,
    required this.username,
    this.avatarId,
    this.avatarBgColor,
  });

  factory FriendInfo.fromMap(Map<String, dynamic> map, String docId) {
    return FriendInfo(
      uid: docId,
      username: map['username'] as String? ?? 'Captain',
      avatarId: map['avatarId'] as String?,
      avatarBgColor: map['avatarBgColor'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'avatarId': avatarId,
      if (avatarBgColor != null) 'avatarBgColor': avatarBgColor,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class FriendsRepository {
  final FirebaseFirestore _firestore;

  FriendsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _friendsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('friends');

  Stream<List<FriendInfo>> streamFriends(String uid) {
    return _friendsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FriendInfo.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<bool> streamIsFriend({required String currentUid, required String targetUid}) {
    return _friendsRef(currentUid).doc(targetUid).snapshots().map((snap) => snap.exists);
  }

  Future<void> addFriend({
    required String currentUid,
    required String targetUid,
    required String targetUsername,
    String? targetAvatarId,
    String? targetAvatarBgColor,
    required String currentUsername,
    String? currentAvatarId,
    String? currentAvatarBgColor,
  }) async {
    final batch = _firestore.batch();

    // Add targetUid to currentUid's friends subcollection
    batch.set(_friendsRef(currentUid).doc(targetUid), {
      'username': targetUsername,
      'avatarId': targetAvatarId,
      'avatarBgColor': ?targetAvatarBgColor,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add currentUid to targetUid's friends subcollection
    batch.set(_friendsRef(targetUid).doc(currentUid), {
      'username': currentUsername,
      'avatarId': currentAvatarId,
      'avatarBgColor': ?currentAvatarBgColor,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> removeFriend({
    required String currentUid,
    required String targetUid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_friendsRef(currentUid).doc(targetUid));
    batch.delete(_friendsRef(targetUid).doc(currentUid));
    await batch.commit();
  }
}
