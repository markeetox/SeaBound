import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/map_layers/artificial_reefs_service.dart';

void main() {
  group('ArtificialReefPoint GeoJSON Parsing Tests', () {
    test('parses GeoJSON feature with full properties correctly', () {
      final feature = {
        'id': '101',
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [-80.1234, 25.5678],
        },
        'properties': {
          'Reef_Name': 'Tenneco Towers',
          'Primary_Material': 'Oil Rig Platform',
          'Water_Depth': '110',
          'Deployment_Date': '1985-09-21',
          'County': 'Broward',
        },
      };

      final reef = ArtificialReefPoint.fromGeoJson(feature);

      expect(reef.id, equals('101'));
      expect(reef.reefName, equals('Tenneco Towers'));
      expect(reef.primaryMaterial, equals('Oil Rig Platform'));
      expect(reef.waterDepthFt, equals('110'));
      expect(reef.deploymentDate, equals('1985-09-21'));
      expect(reef.countyAgency, equals('Broward'));
      expect(reef.longitude, closeTo(-80.1234, 0.0001));
      expect(reef.latitude, closeTo(25.5678, 0.0001));
    });

    test('handles missing or empty optional properties gracefully', () {
      final feature = {
        'geometry': {
          'type': 'Point',
          'coordinates': [-81.0000, 26.0000],
        },
        'properties': {
          'Reef_Name': '',
          'Primary_Material': '',
          'Water_Depth': '0',
        },
      };

      final reef = ArtificialReefPoint.fromGeoJson(feature);

      expect(reef.reefName, equals('Artificial Reef'));
      expect(reef.primaryMaterial, isNull);
      expect(reef.waterDepthFt, isNull);
      expect(reef.deploymentDate, isNull);
      expect(reef.countyAgency, isNull);
    });
  });
}
