import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/trips/trip_model.dart';

void main() {
  group('Trip Sharing and Reaction Serialization Unit Tests', () {
    test('Trip.fromMap parses sharedWith, likedBy, and dislikedBy lists correctly', () {
      final map = {
        'userId': 'owner_1',
        'title': 'Biscayne Bay Deep Sea',
        'date': '2026-10-09T00:00:00.000',
        'locationName': 'Miami Shores',
        'species': ['Mahi Mahi', 'Tuna'],
        'notes': 'Great trip with friends',
        'sharedWith': ['friend_uid_1', 'friend_uid_2'],
        'likedBy': ['user_a', 'user_b'],
        'dislikedBy': ['user_c'],
      };

      final trip = Trip.fromMap(map, 'trip_100');

      expect(trip.id, 'trip_100');
      expect(trip.sharedWith, containsAll(['friend_uid_1', 'friend_uid_2']));
      expect(trip.likedBy, containsAll(['user_a', 'user_b']));
      expect(trip.dislikedBy, contains('user_c'));
      expect(trip.likeCount, 2);
      expect(trip.dislikeCount, 1);
      expect(trip.isLikedBy('user_a'), isTrue);
      expect(trip.isDislikedBy('user_c'), isTrue);
    });

    test('Trip.toMap serializes sharedWith, likedBy, and dislikedBy lists', () {
      final trip = Trip(
        id: 'trip_101',
        userId: 'owner_1',
        title: 'Key West Snapper Run',
        date: DateTime(2026, 10, 9),
        locationName: 'Key West Reef',
        species: const ['Snapper'],
        notes: 'Calm waters',
        sharedWith: const ['friend_uid_A'],
        likedBy: const ['user_x'],
        dislikedBy: const ['user_y'],
      );

      final map = trip.toMap();
      expect(map['sharedWith'], equals(['friend_uid_A']));
      expect(map['likedBy'], equals(['user_x']));
      expect(map['dislikedBy'], equals(['user_y']));
    });
  });
}
