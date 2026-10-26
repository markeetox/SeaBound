import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/profile/friends_repository.dart';

void main() {
  group('FriendInfo Model Unit Tests', () {
    test('FriendInfo.fromMap parses document ID and fields correctly', () {
      final map = {
        'username': 'FirstMateBob',
        'avatarId': 'avatar_3',
      };
      final friend = FriendInfo.fromMap(map, 'user_123');

      expect(friend.uid, 'user_123');
      expect(friend.username, 'FirstMateBob');
      expect(friend.avatarId, 'avatar_3');
    });

    test('FriendInfo.fromMap uses default username when missing', () {
      final friend = FriendInfo.fromMap({}, 'user_456');

      expect(friend.uid, 'user_456');
      expect(friend.username, 'Captain');
      expect(friend.avatarId, isNull);
    });
  });
}
