import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  none,
  sent,
  received,
}

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

class FriendRequest {
  final String fromUid;
  final String fromUsername;
  final String? fromAvatarId;
  final String? fromAvatarBgColor;
  final String toUid;
  final DateTime? createdAt;

  const FriendRequest({
    required this.fromUid,
    required this.fromUsername,
    this.fromAvatarId,
    this.fromAvatarBgColor,
    required this.toUid,
    this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return FriendRequest(
      fromUid: map['fromUid'] as String? ?? docId,
      fromUsername: map['fromUsername'] as String? ?? 'Captain',
      fromAvatarId: map['fromAvatarId'] as String?,
      fromAvatarBgColor: map['fromAvatarBgColor'] as String?,
      toUid: map['toUid'] as String? ?? '',
      createdAt: map['createdAt'] != null ? parseDateTime(map['createdAt']) : null,
    );
  }
}

class FriendsRepository {
  final FirebaseFirestore _firestore;

  FriendsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _friendsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('friends');

  CollectionReference<Map<String, dynamic>> _incomingRequestsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('friend_requests');

  CollectionReference<Map<String, dynamic>> _sentRequestsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('sent_requests');

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  Stream<List<FriendInfo>> streamFriends(String uid) {
    return _friendsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FriendInfo.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<bool> streamIsFriend({required String currentUid, required String targetUid}) {
    return _friendsRef(currentUid).doc(targetUid).snapshots().map((snap) => snap.exists);
  }

  Stream<List<FriendRequest>> streamIncomingRequests(String uid) {
    return _incomingRequestsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FriendRequest.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<FriendRequest>> streamIncomingFriendRequests(String uid) => streamIncomingRequests(uid);

  Stream<FriendRequestStatus> streamFriendRequestStatus({
    required String currentUid,
    required String targetUid,
  }) {
    final sentStream = _sentRequestsRef(currentUid).doc(targetUid).snapshots();
    final incomingStream = _incomingRequestsRef(currentUid).doc(targetUid).snapshots();

    return sentStream.asyncExpand((sentSnap) {
      if (sentSnap.exists) {
        return Stream.value(FriendRequestStatus.sent);
      }
      return incomingStream.map((incomingSnap) {
        if (incomingSnap.exists) {
          return FriendRequestStatus.received;
        }
        return FriendRequestStatus.none;
      });
    });
  }

  Future<void> sendFriendRequest({
    required String currentUid,
    required String currentUsername,
    String? currentAvatarId,
    String? currentAvatarBgColor,
    required String targetUid,
    required String targetUsername,
    String? targetAvatarId,
    String? targetAvatarBgColor,
  }) async {
    final batch = _firestore.batch();

    // Write incoming request to target user
    batch.set(_incomingRequestsRef(targetUid).doc(currentUid), {
      'fromUid': currentUid,
      'fromUsername': currentUsername,
      'fromAvatarId': currentAvatarId,
      'fromAvatarBgColor': currentAvatarBgColor,
      'toUid': targetUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Write sent request to current user
    batch.set(_sentRequestsRef(currentUid).doc(targetUid), {
      'toUid': targetUid,
      'toUsername': targetUsername,
      'toAvatarId': targetAvatarId,
      'toAvatarBgColor': targetAvatarBgColor,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Write notification to target user
    batch.set(_notificationsRef(targetUid).doc(), {
      'title': 'New Friend Request',
      'message': '$currentUsername sent you a friend request.',
      'fromUid': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    await batch.commit();
  }

  Future<void> cancelFriendRequest({
    required String currentUid,
    required String targetUid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_incomingRequestsRef(targetUid).doc(currentUid));
    batch.delete(_sentRequestsRef(currentUid).doc(targetUid));
    await batch.commit();
  }

  Future<void> approveFriendRequest({
    required String currentUid,
    required String currentUsername,
    String? currentAvatarId,
    String? currentAvatarBgColor,
    required String targetUid,
    required String targetUsername,
    String? targetAvatarId,
    String? targetAvatarBgColor,
  }) async {
    final batch = _firestore.batch();

    // Create mutual friendship records
    batch.set(_friendsRef(currentUid).doc(targetUid), {
      'username': targetUsername,
      'avatarId': targetAvatarId,
      if (targetAvatarBgColor != null) 'avatarBgColor': targetAvatarBgColor,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_friendsRef(targetUid).doc(currentUid), {
      'username': currentUsername,
      'avatarId': currentAvatarId,
      if (currentAvatarBgColor != null) 'avatarBgColor': currentAvatarBgColor,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Delete request documents
    batch.delete(_incomingRequestsRef(currentUid).doc(targetUid));
    batch.delete(_sentRequestsRef(targetUid).doc(currentUid));

    // Send notification to requesting user
    batch.set(_notificationsRef(targetUid).doc(), {
      'title': 'Friend Request Approved',
      'message': '$currentUsername accepted your friend request! You are now friends.',
      'fromUid': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    await batch.commit();
  }

  Future<void> denyFriendRequest({
    required String currentUid,
    required String targetUid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_incomingRequestsRef(currentUid).doc(targetUid));
    batch.delete(_sentRequestsRef(targetUid).doc(currentUid));
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
