import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'weather_alert_model.dart';

class AlertsRepository {
  final http.Client _client;

  AlertsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<WeatherAlert>> fetchActiveAlerts(double lat, double lon) async {
    final formattedLat = lat.toStringAsFixed(4);
    final formattedLon = lon.toStringAsFixed(4);
    final url =
        'https://api.weather.gov/alerts/active?point=$formattedLat,$formattedLon';

    final headers = <String, String>{
      'Accept': 'application/geo+json',
    };

    if (!kIsWeb) {
      headers['User-Agent'] = 'Seabound (contact: support@seabound.app)';
    }

    final response = await _client.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];
      final alerts = features
          .map((f) => WeatherAlert.fromJson(f as Map<String, dynamic>))
          .toList();
      return WeatherAlert.sortAlerts(alerts);
    } else if (response.statusCode == 404 || response.statusCode == 400) {
      throw OutOfCoverageException();
    } else {
      throw Exception(
          'Failed to fetch alerts from NWS (HTTP ${response.statusCode})');
    }
  }
}

class OutOfCoverageException implements Exception {
  const OutOfCoverageException();

  @override
  String toString() =>
      'Active weather alerts are unavailable for this point (NWS covers US areas only).';
}
