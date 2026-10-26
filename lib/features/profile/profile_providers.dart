import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'friends_repository.dart';
import 'profile_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository();
});

final userFriendsStreamProvider = StreamProvider<List<FriendInfo>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.streamFriends(user.uid);
});

final isFriendStreamProvider = StreamProvider.family<bool, String>((ref, targetUid) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null || user.uid == targetUid) {
    return Stream.value(false);
  }
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.streamIsFriend(currentUid: user.uid, targetUid: targetUid);
});

final incomingFriendRequestsStreamProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.streamIncomingFriendRequests(user.uid);
});

final friendRequestStatusStreamProvider =
    StreamProvider.family<FriendRequestStatus, String>((ref, targetUid) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null || user.uid == targetUid) {
    return Stream.value(FriendRequestStatus.none);
  }
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.streamFriendRequestStatus(
    currentUid: user.uid,
    targetUid: targetUid,
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final userDocStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value(null);
  }
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserDocStream(user.uid);
});

final userEarnedBadgesProvider =
    StreamProvider<Map<String, DateTime>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value({});
  }
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserEarnedBadgesStream(user.uid);
});

final publicProfileDocProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserDocStream(uid);
});

final publicProfileBadgesProvider =
    StreamProvider.family<Map<String, DateTime>, String>((ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserEarnedBadgesStream(uid);
});
