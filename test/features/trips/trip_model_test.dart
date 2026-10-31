import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/trips/trip_model.dart';

void main() {
  group('Trip Model Tests', () {
    test('Trip.fromMap parses map correctly with Timestamps and start/end coordinates', () {
      final now = DateTime(2025, 5, 10, 14, 30);
      final map = {
        'userId': 'user123',
        'title': 'Deep Sea Fishing',
        'date': Timestamp.fromDate(now),
        'locationName': 'Pacific Ocean',
        'species': ['Tuna', 'Marlin'],
        'notes': 'Great weather and catch.',
        'startCoordinates': {'lat': 25.7617, 'lng': -80.1918},
        'endCoordinates': {'lat': 25.8000, 'lng': -80.1200},
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
      expect(trip.startLatLng, isNotNull);
      expect(trip.startLatLng!.latitude, 25.7617);
      expect(trip.startLatLng!.longitude, -80.1918);
      expect(trip.endLatLng, isNotNull);
      expect(trip.endLatLng!.latitude, 25.8000);
      expect(trip.endLatLng!.longitude, -80.1200);
    });

    test('Trip.toMap produces correct map representation with start/end coordinates', () {
      final date = DateTime(2025, 6, 1);
      final trip = Trip(
        id: 'doc_123',
        userId: 'user_xyz',
        title: 'Lake Voyage',
        date: date,
        locationName: 'Lake Tahoe',
        species: ['Trout', 'Bass'],
        notes: 'Calm waters.',
        startCoordinates: const {'lat': 39.0968, 'lng': -120.0324},
        endCoordinates: const {'lat': 39.1200, 'lng': -120.0100},
      );

      final map = trip.toMap();

      expect(map['userId'], 'user_xyz');
      expect(map['title'], 'Lake Voyage');
      expect(map['locationName'], 'Lake Tahoe');
      expect(map['species'], ['Trout', 'Bass']);
      expect(map['notes'], 'Calm waters.');
      expect(map['date'], isA<Timestamp>());
      expect((map['date'] as Timestamp).toDate(), date);
      expect(map['startCoordinates'], equals({'lat': 39.0968, 'lng': -120.0324}));
      expect(map['endCoordinates'], equals({'lat': 39.1200, 'lng': -120.0100}));
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
        startCoordinates: {'lat': 10.0, 'lng': 20.0},
      );

      expect(updated.id, '1');
      expect(updated.title, 'New Title');
      expect(updated.species, ['Fish A', 'Fish B']);
      expect(updated.locationName, 'Loc 1');
      expect(updated.startLatLng?.latitude, 10.0);
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
