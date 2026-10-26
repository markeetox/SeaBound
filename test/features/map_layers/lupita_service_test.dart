import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/map_layers/lupita_service.dart';

void main() {
  group('Lupita Models & Data Parsing Tests', () {
    test('LupitaData.fromJson parses species and spot details correctly', () {
      final sampleJson = {
        'version': 1,
        'generated_utc': '2026-10-24T20:23:29Z',
        'disclaimer': 'Habitat scores for reference.',
        'species': [
          {
            'id': 'cobia',
            'name': 'Cobia',
            'sci': 'Rachycentron canadum',
            'color': '#c084fc',
            'status': 'ok',
            'message': '',
            'spots': 20,
            'specs': [
              ['Diet', 'Crabs, fish and squid'],
              ['Adult depth', '30-70 ft']
            ]
          }
        ],
        'spots': [
          {
            'id': 'cobia-1',
            'species': 'cobia',
            'title': 'Ultra Freeze Wreck',
            'score': 0.85,
            'confidence': 'High',
            'data_coverage': 0.9,
            'coords': [-80.1, 25.62],
            'sea': {'summary': 'Calm 1-2ft waves'},
            'timing': {
              'window': {
                'start_utc': '2026-10-24T20:00:00Z',
                'end_utc': '2026-10-24T23:00:00Z',
                'score': 0.92
              },
              'why': ['Incoming tide peak', 'Major solunar period']
            },
            'reasons': [
              ['static', 'Depth is 12m nearshore structure'],
              ['modeled', 'Water temperature 28.8C']
            ]
          }
        ]
      };

      final data = LupitaData.fromJson(sampleJson);

      expect(data.version, equals(1));
      expect(data.species.length, equals(1));

      final cobia = data.species.first;
      expect(cobia.id, equals('cobia'));
      expect(cobia.name, equals('Cobia'));
      expect(cobia.colorHex, equals('#c084fc'));
      expect(cobia.specs.length, equals(2));
      expect(cobia.specs.first.label, equals('Diet'));
      expect(cobia.specs.first.value, equals('Crabs, fish and squid'));
      expect(cobia.imageUrl, equals('https://cdn.jsdelivr.net/gh/markeetox/lupita@data/api/v1/img/cobia.png'));

      expect(cobia.spots.length, equals(1));
      final spot = cobia.spots.first;
      expect(spot.id, equals('cobia-1'));
      expect(spot.title, equals('Ultra Freeze Wreck'));
      expect(spot.score, equals(0.85));
      expect(spot.confidence, equals('High'));
      expect(spot.latitude, equals(25.62));
      expect(spot.longitude, equals(-80.1));
      expect(spot.seaSummary, equals('Calm 1-2ft waves'));
      expect(spot.reasons.length, equals(2));
      expect(spot.reasons.first.category, equals('static'));
      expect(spot.reasons.first.text, equals('Depth is 12m nearshore structure'));

      expect(spot.biteWindow, isNotNull);
      expect(spot.biteWindow!.score, equals(0.92));
      expect(spot.biteWindow!.startTime, equals(DateTime.parse('2026-10-24T20:00:00Z')));
      expect(spot.biteWindow!.why, contains('Incoming tide peak'));
    });
  });
}
