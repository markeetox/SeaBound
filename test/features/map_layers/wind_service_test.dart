import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seabound/features/map_layers/wind_service.dart';

void main() {
  setUp(() {
    WindService.clearCache();
  });

  group('NdbcStationObs Model & Conversion Tests', () {
    test('mpsToMph converts meters/sec to mph correctly', () {
      expect(NdbcStationObs.mpsToMph(1.0), closeTo(2.23694, 0.001));
      expect(NdbcStationObs.mpsToMph(5.0), closeTo(11.1847, 0.01));
    });

    test('degreesToCompass returns correct compass direction', () {
      expect(NdbcStationObs.degreesToCompass(0), equals('N'));
      expect(NdbcStationObs.degreesToCompass(90), equals('E'));
      expect(NdbcStationObs.degreesToCompass(180), equals('S'));
      expect(NdbcStationObs.degreesToCompass(270), equals('W'));
      expect(NdbcStationObs.degreesToCompass(null), equals('N/A'));
    });
  });

  group('WindService NDBC Parsing Tests', () {
    test('parses NDBC latest_obs text response correctly', () async {
      const mockResponseBody = '''
#STN       LAT      LON  YYYY MM DD hh mm WDIR WSPD   GST WVHT  DPD APD MWD   PRES  PTDY  ATMP  WTMP  DEWP  VIS   TIDE
#text      deg      deg   yr mo day hr mn degT  m/s   m/s   m   sec sec degT   hPa   hPa  degC  degC  degC  nmi     ft
41009    28.51   -80.18  2026 10 08 21 00 180   5.0   7.0  1.2  MM   MM  MM 1014.8    MM  25.9  26.6    MM   MM     MM
LONF1    24.84   -80.60  2026 10 08 21 00  MM    MM    MM   MM  MM   MM  MM 1015.0    MM  26.0  27.0    MM   MM     MM
''';

      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.ndbc.noaa.gov' ||
            request.url.host == 'api.allorigins.win') {
          return http.Response(mockResponseBody, 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = WindService(client: mockClient);
      final stations = await service.fetchNdbcStations();

      expect(stations.length, equals(2));

      final buoy = stations.firstWhere((s) => s.stationId == '41009');
      expect(buoy.latitude, equals(28.51));
      expect(buoy.longitude, equals(-80.18));
      expect(buoy.windDirectionDeg, equals(180.0));
      expect(buoy.windSpeedMph, closeTo(11.185, 0.01));
      expect(buoy.windGustMph, closeTo(15.659, 0.01));
      expect(buoy.waveHeightFt, closeTo(3.937, 0.01));

      final lonf1 = stations.firstWhere((s) => s.stationId == 'LONF1');
      expect(lonf1.windDirectionDeg, isNull);
      expect(lonf1.windSpeedMph, isNull);
      expect(lonf1.windGustMph, isNull);
    });

    test('falls back to proxy endpoint when direct request fails', () async {
      const mockResponseBody = '''
#STN       LAT      LON  YYYY MM DD hh mm WDIR WSPD   GST WVHT  DPD APD MWD   PRES  PTDY  ATMP  WTMP  DEWP  VIS   TIDE
#text      deg      deg   yr mo day hr mn degT  m/s   m/s   m   sec sec degT   hPa   hPa  degC  degC  degC  nmi     ft
41009    28.51   -80.18  2026 10 08 21 00 180   5.0   7.0  1.2  MM   MM  MM 1014.8    MM  25.9  26.6    MM   MM     MM
''';

      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.ndbc.noaa.gov') {
          throw Exception('CORS network failure');
        }
        if (request.url.host == 'corsproxy.io' ||
            request.url.host == 'api.codetabs.com' ||
            request.url.host == 'api.allorigins.win') {
          return http.Response(mockResponseBody, 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = WindService(client: mockClient);
      final stations = await service.fetchNdbcStations();

      expect(stations.length, equals(1));
      expect(stations.first.stationId, equals('41009'));
    });
  });
}
