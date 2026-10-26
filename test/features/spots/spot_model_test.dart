import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/spots/spot_model.dart';

void main() {
  group('Spot Model Tests', () {
    test('Spot.fromMap parses map correctly with Timestamps', () {
      final now = DateTime(2025, 5, 12, 10, 0);
      final map = {
        'userId': 'user_456',
        'authorName': 'Captain Jack',
        'name': 'Coral Reef Anchorage',
        'description': 'Shallow reef with abundant marine life.',
        'latitude': 25.7617,
        'longitude': -80.1918,
        'species': ['Snapper', 'Grouper'],
        'createdAt': Timestamp.fromDate(now),
      };

      final spot = Spot.fromMap(map, 'spot_123');

      expect(spot.id, 'spot_123');
      expect(spot.userId, 'user_456');
      expect(spot.authorName, 'Captain Jack');
      expect(spot.name, 'Coral Reef Anchorage');
      expect(spot.description, 'Shallow reef with abundant marine life.');
      expect(spot.latitude, 25.7617);
      expect(spot.longitude, -80.1918);
      expect(spot.species, ['Snapper', 'Grouper']);
      expect(spot.createdAt, now);
    });

    test('Spot.toMap converts to Map representation', () {
      final date = DateTime(2025, 6, 20);
      final spot = Spot(
        id: 'spot_99',
        userId: 'u_11',
        authorName: 'Captain Ahab',
        name: 'Deep Trench',
        description: 'Challenging deep waters.',
        latitude: 24.5,
        longitude: -81.7,
        species: const ['Marlin'],
        createdAt: date,
      );

      final map = spot.toMap();

      expect(map['userId'], 'u_11');
      expect(map['authorName'], 'Captain Ahab');
      expect(map['name'], 'Deep Trench');
      expect(map['description'], 'Challenging deep waters.');
      expect(map['latitude'], 24.5);
      expect(map['longitude'], -81.7);
      expect(map['species'], ['Marlin']);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('Spot.copyWith modifies fields correctly', () {
      final spot = Spot(
        id: '1',
        userId: 'u1',
        authorName: 'Author A',
        name: 'Spot A',
        description: 'Desc A',
        latitude: 10.0,
        longitude: 20.0,
        species: const ['Fish 1'],
      );

      final updated = spot.copyWith(
        name: 'Updated Spot',
        latitude: 11.5,
        species: ['Fish 1', 'Fish 2'],
      );

      expect(updated.id, '1');
      expect(updated.name, 'Updated Spot');
      expect(updated.latitude, 11.5);
      expect(updated.longitude, 20.0);
      expect(updated.species, ['Fish 1', 'Fish 2']);
      expect(updated.authorName, 'Author A');
    });

    test('Spot equality and hashCode', () {
      final spot1 = Spot(
        id: 's1',
        userId: 'u1',
        authorName: 'Auth1',
        name: 'Bay Spot',
        description: 'Quiet bay',
        latitude: 25.0,
        longitude: -80.0,
        species: const ['Tarpon'],
      );

      final spot2 = Spot(
        id: 's1',
        userId: 'u1',
        authorName: 'Auth1',
        name: 'Bay Spot',
        description: 'Quiet bay',
        latitude: 25.0,
        longitude: -80.0,
        species: const ['Tarpon'],
      );

      expect(spot1, equals(spot2));
      expect(spot1.hashCode, equals(spot2.hashCode));
    });
  });
}
