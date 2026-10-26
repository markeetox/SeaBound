import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/map_layer_config.dart';

class TideStation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String state;

  const TideStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.state,
  });

  factory TideStation.fromJson(Map<String, dynamic> json) {
    return TideStation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Tide Station',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      state: json['state'] as String? ?? '',
    );
  }
}

class TidePrediction {
  final DateTime time;
  final double value;
  final String type; // 'H' for High, 'L' for Low

  const TidePrediction({
    required this.time,
    required this.value,
    required this.type,
  });

  factory TidePrediction.fromJson(Map<String, dynamic> json) {
    return TidePrediction(
      time: DateTime.parse(json['t'] as String),
      value: double.tryParse(json['v'] as String? ?? '0.0') ?? 0.0,
      type: json['type'] as String? ?? '',
    );
  }
}

class TideService {
  final http.Client _client;

  TideService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<TideStation>> fetchTideStations() async {
    final response =
        await _client.get(Uri.parse(MapLayerConfig.noaaTideStationsUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final stationsList = data['stations'] as List<dynamic>? ?? [];
      return stationsList
          .map((s) => TideStation.fromJson(s as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load NOAA tide stations (code: ${response.statusCode})');
    }
  }

  Future<List<TidePrediction>> fetchStationPredictions(String stationId) async {
    final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final uri = Uri.parse(MapLayerConfig.noaaTideDataGetterUrl).replace(
      queryParameters: {
        'begin_date': todayStr,
        'end_date': todayStr,
        'station': stationId,
        'product': 'predictions',
        'interval': 'hilo',
        'datum': 'MLLW',
        'time_zone': 'lst_ldt',
        'units': 'english',
        'format': 'json',
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data.containsKey('error')) {
        throw Exception(data['error']['message'] ?? 'NOAA API error');
      }
      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions
          .map((p) => TidePrediction.fromJson(p as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load tide predictions (code: ${response.statusCode})');
    }
  }
}
