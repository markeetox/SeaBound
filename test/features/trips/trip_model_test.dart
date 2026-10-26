import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/trips/trip_model.dart';

void main() {
  group('Trip Model Tests', () {
    test('Trip.fromMap parses map correctly with Timestamps', () {
      final now = DateTime(2025, 5, 10, 14, 30);
      final map = {
        'userId': 'user123',
        'title': 'Deep Sea Fishing',
        'date': Timestamp.fromDate(now),
        'locationName': 'Pacific Ocean',
        'species': ['Tuna', 'Marlin'],
        'notes': 'Great weather and catch.',
        'createdAt': Timestamp.fromDate(now),
      };

      final trip = Trip.fromMap(map, 'doc_abc');

      expect(trip.id, 'doc_abc');
      expect(trip.userId, 'user123');
      expect(trip.title, 'Deep Sea Fishing');
      expect(trip.date, now);
      expect(trip.locationName, 'Pacific Ocean');
      expect(trip.species, ['Tuna', 'Marlin']);
      expect(trip.notes, 'Great weather and catch.');
    });

    test('Trip.toMap produces correct map representation', () {
      final date = DateTime(2025, 6, 1);
      final trip = Trip(
        id: 'doc_123',
        userId: 'user_xyz',
        title: 'Lake Voyage',
        date: date,
        locationName: 'Lake Tahoe',
        species: ['Trout', 'Bass'],
        notes: 'Calm waters.',
      );

      final map = trip.toMap();

      expect(map['userId'], 'user_xyz');
      expect(map['title'], 'Lake Voyage');
      expect(map['locationName'], 'Lake Tahoe');
      expect(map['species'], ['Trout', 'Bass']);
      expect(map['notes'], 'Calm waters.');
      expect(map['date'], isA<Timestamp>());
      expect((map['date'] as Timestamp).toDate(), date);
    });

    test('Trip.copyWith modifies fields correctly', () {
      final trip = Trip(
        id: '1',
        userId: 'u1',
        title: 'Old Title',
        date: DateTime(2025, 1, 1),
        locationName: 'Loc 1',
        species: const ['Fish A'],
        notes: 'Note A',
      );

      final updated = trip.copyWith(
        title: 'New Title',
        species: ['Fish A', 'Fish B'],
      );

      expect(updated.id, '1');
      expect(updated.title, 'New Title');
      expect(updated.species, ['Fish A', 'Fish B']);
      expect(updated.locationName, 'Loc 1');
    });

    test('Trip equality and hashCode', () {
      final date = DateTime(2025, 3, 15);
      final trip1 = Trip(
        id: 't1',
        userId: 'u1',
        title: 'Trip 1',
        date: date,
        locationName: 'Dock A',
        species: ['Cod'],
        notes: 'Sunny',
      );

      final trip2 = Trip(
        id: 't1',
        userId: 'u1',
        title: 'Trip 1',
        date: date,
        locationName: 'Dock A',
        species: ['Cod'],
        notes: 'Sunny',
      );

      expect(trip1, equals(trip2));
      expect(trip1.hashCode, equals(trip2.hashCode));
    });
  });
}
