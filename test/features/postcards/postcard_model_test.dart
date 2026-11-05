import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/postcards/postcard_model.dart';
import 'package:seabound/features/postcards/postcards_repository.dart';

void main() {
  group('Postcard Models Unit Tests', () {
    test('Postcard fromMap and toMap serialization', () {
      final now = DateTime(2026, 11, 4, 12, 0);
      final postcard = Postcard(
        id: 'card_123',
        title: 'Biscayne Lighthouse',
        description: 'Historical navigation beacon.',
        locationName: 'Biscayne Bay',
        imageUrl: 'https://example.com/lighthouse.jpg',
        zone: const CircleZone(lat: 25.67, lng: -80.15, radiusMeters: 300.0),
        geohash: 'dhwf',
        active: true,
        createdAt: now,
        createdBy: 'admin_1',
      );

      final map = postcard.toMap();
      expect(map['title'], 'Biscayne Lighthouse');
      expect(map['description'], 'Historical navigation beacon.');
      expect(map['locationName'], 'Biscayne Bay');
      expect(map['imageUrl'], 'https://example.com/lighthouse.jpg');
      expect(map['geohash'], 'dhwf');
      expect(map['active'], true);
      expect(map['createdBy'], 'admin_1');

      final fromMap = Postcard.fromMap({
        'title': 'Biscayne Lighthouse',
        'description': 'Historical navigation beacon.',
        'locationName': 'Biscayne Bay',
        'imageUrl': 'https://example.com/lighthouse.jpg',
        'zone': {'lat': 25.67, 'lng': -80.15, 'radiusMeters': 300.0},
        'geohash': 'dhwf',
        'active': true,
        'createdAt': now.toIso8601String(),
        'createdBy': 'admin_1',
      }, 'card_123');

      expect(fromMap.id, 'card_123');
      expect(fromMap.title, 'Biscayne Lighthouse');
      expect(fromMap.zone.lat, 25.67);
      expect(fromMap.zone.lng, -80.15);
      expect(fromMap.zone.radiusMeters, 300.0);
    });

    test('EarnedPostcard fromMap and toMap serialization', () {
      final now = DateTime(2026, 11, 4, 14, 30);
      final earned = EarnedPostcard(
        postcardId: 'card_123',
        earnedAt: now,
        title: 'Biscayne Lighthouse',
      );

      final map = earned.toMap();
      expect(map['postcardId'], 'card_123');
      expect(map['title'], 'Biscayne Lighthouse');

      final fromMap = EarnedPostcard.fromMap({
        'postcardId': 'card_123',
        'earnedAt': now.toIso8601String(),
        'title': 'Biscayne Lighthouse',
      }, 'card_123');

      expect(fromMap.postcardId, 'card_123');
      expect(fromMap.title, 'Biscayne Lighthouse');
    });

    test('Repository streams return empty when uid is empty', () async {
      final repo = PostcardsRepository();
      final earnedCards = await repo.streamUserEarnedPostcards('').first;
      expect(earnedCards, isEmpty);
    });
  });
}
