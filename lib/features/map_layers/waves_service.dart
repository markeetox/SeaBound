import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/map_layer_config.dart';

class HourlyWaveEntry {
  final DateTime time;
  final double waveHeightFt;
  final double? wavePeriodSec;
  final double? waveDirectionDeg;
  final double? swellHeightFt;
  final double? swellPeriodSec;

  const HourlyWaveEntry({
    required this.time,
    required this.waveHeightFt,
    this.wavePeriodSec,
    this.waveDirectionDeg,
    this.swellHeightFt,
    this.swellPeriodSec,
  });

  static double metersToFeet(double meters) => meters * 3.281;

  static String degreesToCompass(double? degrees) {
    if (degrees == null) return 'N/A';
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees + 11.25) % 360 / 22.5).floor();
    return directions[index];
  }
}

class WavePointData {
  final double latitude;
  final double longitude;
  final List<HourlyWaveEntry> hourlyEntries;

  const WavePointData({
    required this.latitude,
    required this.longitude,
    required this.hourlyEntries,
  });

  HourlyWaveEntry getForOffset(int hourOffset) {
    if (hourlyEntries.isEmpty) {
      return HourlyWaveEntry(
        time: DateTime.now().add(Duration(hours: hourOffset)),
        waveHeightFt: 0.0,
      );
    }

    final targetTime = DateTime.now().add(Duration(hours: hourOffset));
    HourlyWaveEntry closest = hourlyEntries.first;
    int minDiff = (closest.time.difference(targetTime)).abs().inMinutes;

    for (final entry in hourlyEntries) {
      final diff = (entry.time.difference(targetTime)).abs().inMinutes;
      if (diff < minDiff) {
        minDiff = diff;
        closest = entry;
      }
    }
    return closest;
  }
}

class WavesCacheEntry {
  final String key;
  final List<WavePointData> data;
  final DateTime fetchedAt;

  WavesCacheEntry({
    required this.key,
    required this.data,
    required this.fetchedAt,
  });

  bool get isValid => DateTime.now().difference(fetchedAt).inMinutes < 10;
}

class WavesService {
  final http.Client _client;
  static final Map<String, WavesCacheEntry> _cache = {};

  WavesService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<WavePointData>> fetchGridWaves({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    // Round bounds to 2 decimal places for cache key
    final cacheKey =
        '${minLat.toStringAsFixed(2)},${maxLat.toStringAsFixed(2)},${minLng.toStringAsFixed(2)},${maxLng.toStringAsFixed(2)}';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data;
    }

    // Generate 6x6 grid of lat/lngs
    final latList = <double>[];
    final lngList = <double>[];

    final latStep = (maxLat - minLat) / 5;
    final lngStep = (maxLng - minLng) / 5;

    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 6; j++) {
        latList.add(double.parse((minLat + latStep * i).toStringAsFixed(4)));
        lngList.add(double.parse((minLng + lngStep * j).toStringAsFixed(4)));
      }
    }

    final latParam = latList.join(',');
    final lngParam = lngList.join(',');

    final uri = Uri.parse(
      '${MapLayerConfig.openMeteoMarineUrl}?latitude=$latParam&longitude=$lngParam&hourly=wave_height,wave_period,wave_direction,swell_wave_height,swell_wave_period&forecast_days=3&timezone=auto',
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load wave data (${response.statusCode})');
    }

    final dynamic decoded = json.decode(response.body);

    final List<WavePointData> results = [];

    if (decoded is List) {
      for (final item in decoded) {
        results.add(_parsePointData(item));
      }
    } else if (decoded is Map<String, dynamic>) {
      results.add(_parsePointData(decoded));
    }

    _cache[cacheKey] = WavesCacheEntry(
      key: cacheKey,
      data: results,
      fetchedAt: DateTime.now(),
    );

    return results;
  }

  WavePointData _parsePointData(Map<String, dynamic> jsonMap) {
    final lat = (jsonMap['latitude'] as num).toDouble();
    final lng = (jsonMap['longitude'] as num).toDouble();

    final hourly = jsonMap['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourly['time'] as List?)?.cast<String>() ?? [];
    final heights = hourly['wave_height'] as List? ?? [];
    final periods = hourly['wave_period'] as List? ?? [];
    final directions = hourly['wave_direction'] as List? ?? [];
    final swellHeights = hourly['swell_wave_height'] as List? ?? [];
    final swellPeriods = hourly['swell_wave_period'] as List? ?? [];

    final entries = <HourlyWaveEntry>[];

    for (int i = 0; i < times.length; i++) {
      final timeStr = times[i];
      final rawHeight = i < heights.length && heights[i] != null
          ? (heights[i] as num).toDouble()
          : 0.0;

      final rawPeriod = i < periods.length && periods[i] != null
          ? (periods[i] as num).toDouble()
          : null;

      final rawDir = i < directions.length && directions[i] != null
          ? (directions[i] as num).toDouble()
          : null;

      final rawSwellH = i < swellHeights.length && swellHeights[i] != null
          ? (swellHeights[i] as num).toDouble()
          : null;

      final rawSwellP = i < swellPeriods.length && swellPeriods[i] != null
          ? (swellPeriods[i] as num).toDouble()
          : null;

      entries.add(
        HourlyWaveEntry(
          time: DateTime.tryParse(timeStr) ?? DateTime.now(),
          waveHeightFt: HourlyWaveEntry.metersToFeet(rawHeight),
          wavePeriodSec: rawPeriod,
          waveDirectionDeg: rawDir,
          swellHeightFt: rawSwellH != null
              ? HourlyWaveEntry.metersToFeet(rawSwellH)
              : null,
          swellPeriodSec: rawSwellP,
        ),
      );
    }

    return WavePointData(
      latitude: lat,
      longitude: lng,
      hourlyEntries: entries,
    );
  }
}
