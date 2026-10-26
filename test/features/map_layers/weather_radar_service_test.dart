import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seabound/features/map_layers/weather_radar_service.dart';

void main() {
  group('WeatherRadarService Unit Tests', () {
    test('parses RainViewer JSON response correctly and builds tile URLs', () async {
      const mockResponseBody = '''
{
  "version": "2.0",
  "generated": 1700000000,
  "host": "https://tilecache.rainviewer.com",
  "radar": {
    "past": [
      {"time": 1700000000, "path": "/v2/radar/frame0"}
    ],
    "nowcast": [
      {"time": 1700003600, "path": "/v2/radar/frame1"}
    ]
  }
}
''';

      final mockClient = MockClient((request) async {
        return http.Response(mockResponseBody, 200);
      });

      final service = WeatherRadarService(client: mockClient);
      final response = await service.fetchRadarFrames();

      expect(response.host, equals('https://tilecache.rainviewer.com'));
      expect(response.past.length, equals(1));
      expect(response.nowcast.length, equals(1));

      final liveUrl = response.getTileUrlForOffset(0, tileSize: 512, smooth: true);
      expect(liveUrl, equals('https://tilecache.rainviewer.com/v2/radar/frame0/512/{z}/{x}/{y}/2/1_1.png'));
    });
  });
}
