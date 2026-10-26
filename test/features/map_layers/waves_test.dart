import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/map_layers/waves_service.dart';

void main() {
  group('HourlyWaveEntry Unit Tests', () {
    test('metersToFeet converts meters to feet correctly', () {
      expect(HourlyWaveEntry.metersToFeet(0.0), equals(0.0));
      expect(HourlyWaveEntry.metersToFeet(1.0), closeTo(3.281, 0.001));
      expect(HourlyWaveEntry.metersToFeet(2.0), closeTo(6.562, 0.001));
    });

    test('degreesToCompass returns correct compass direction strings', () {
      expect(HourlyWaveEntry.degreesToCompass(0.0), equals('N'));
      expect(HourlyWaveEntry.degreesToCompass(90.0), equals('E'));
      expect(HourlyWaveEntry.degreesToCompass(180.0), equals('S'));
      expect(HourlyWaveEntry.degreesToCompass(270.0), equals('W'));
      expect(HourlyWaveEntry.degreesToCompass(45.0), equals('NE'));
      expect(HourlyWaveEntry.degreesToCompass(225.0), equals('SW'));
      expect(HourlyWaveEntry.degreesToCompass(null), equals('N/A'));
    });
  });

  group('WavePointData Unit Tests', () {
    test('getForOffset returns closest hourly entry', () {
      final now = DateTime.now();
      final entry0 = HourlyWaveEntry(
        time: now,
        waveHeightFt: 1.5,
      );
      final entry3 = HourlyWaveEntry(
        time: now.add(const Duration(hours: 3)),
        waveHeightFt: 3.5,
      );

      final point = WavePointData(
        latitude: 25.0,
        longitude: -80.0,
        hourlyEntries: [entry0, entry3],
      );

      expect(point.getForOffset(0).waveHeightFt, equals(1.5));
      expect(point.getForOffset(3).waveHeightFt, equals(3.5));
    });
  });
}
