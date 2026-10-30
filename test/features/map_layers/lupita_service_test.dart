import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/map_layers/lupita_service.dart';

void main() {
  group('Lupita Models & Catalog Merger Tests', () {
    test('LupitaData.fromJson parses species, regulations, and spot details correctly', () {
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
            ],
            'regulations': {
              'summary': 'Regulated species - See MyFWC/NOAA guidelines',
              'min_size': '36 inch FL',
              'max_size': 'None',
              'bag_limit': '1 per person',
              'season': 'Open year-round',
              'jurisdiction': 'Atlantic State & Federal Waters',
              'source_name': 'MyFWC Saltwater Regulations',
              'source_url': 'https://myfwc.com/fishing/saltwater/recreational/'
            }
          },
          {
            'id': 'tarpon',
            'name': 'Tarpon',
            'sci': 'Megalops atlanticus',
            'color': '#38bdf8',
            'status': 'ok',
            'message': '',
            'spots': 0,
            'specs': [
              ['Diet', 'Fishes and crabs']
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
            'location': [
              ['Water depth', 'About 30 m'],
              ['Surface temp', '28.8 C']
            ],
            'reasons': [
              ['static', 'Depth is 12m nearshore structure'],
              ['modeled', 'Water temperature 28.8C']
            ]
          }
        ]
      };

      final data = LupitaData.fromJson(sampleJson);

      expect(data.version, equals(1));
      expect(data.species.length, equals(2));
      expect(data.speciesWithPredictionsCount, equals(1));
      expect(data.status, equals(LupitaSyncStatus.fresh));
      expect(data.catalogGeneratedUtc, equals('2026-10-24T20:23:29Z'));

      final cobia = data.species.firstWhere((s) => s.id == 'cobia');
      expect(cobia.name, equals('Cobia'));
      expect(cobia.sci, equals('Rachycentron canadum'));
      expect(cobia.colorHex, equals('#c084fc'));
      expect(cobia.specs.length, equals(2));
      expect(cobia.specs.first.label, equals('Diet'));
      expect(cobia.specs.first.value, equals('Crabs, fish and squid'));
      expect(cobia.imageUrl, equals('https://cdn.jsdelivr.net/gh/markeetox/lupita@data/api/v1/img/cobia.png'));

      expect(cobia.regulations, isNotNull);
      expect(cobia.regulations!.summary, contains('Regulated species'));
      expect(cobia.regulations!.minSize, equals('36 inch FL'));

      expect(cobia.spots.length, equals(1));
      final spot = cobia.spots.first;
      expect(spot.id, equals('cobia-1'));
      expect(spot.title, equals('Ultra Freeze Wreck'));
      expect(spot.score, equals(0.85));
      expect(spot.confidence, equals('High'));

      final tarpon = data.species.firstWhere((s) => s.id == 'tarpon');
      expect(tarpon.name, equals('Tarpon'));
      expect(tarpon.spots, isEmpty);
    });

    test('LupitaData handles structurally valid empty prediction runs (spots: []) correctly', () {
      final sampleJsonNoSpots = {
        'version': 1,
        'generated_utc': '2026-10-24T20:23:29Z',
        'disclaimer': 'Catalog only',
        'species': [
          {
            'id': 'cobia',
            'name': 'Cobia',
            'sci': 'Rachycentron canadum',
            'color': '#c084fc',
            'status': 'ok',
            'message': '',
            'spots': 0
          }
        ],
        'spots': []
      };

      final data = LupitaData.fromJson(sampleJsonNoSpots);
      expect(data.species.length, equals(1));
      expect(data.allSpots, isEmpty);
      expect(data.speciesWithPredictionsCount, equals(0));
      expect(data.status, equals(LupitaSyncStatus.empty));
    });
  });
}
