import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/map_layer_config.dart';

class NoFishingZone {
  final String id;
  final String siteName;
  final String protectionLevel;
  final String governance;
  final String url;
  final List<List<LatLng>> polygonRings;

  const NoFishingZone({
    required this.id,
    required this.siteName,
    required this.protectionLevel,
    required this.governance,
    required this.url,
    required this.polygonRings,
  });

  factory NoFishingZone.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};

    final id = attributes['OBJECTID']?.toString() ??
        attributes['SITE_ID']?.toString() ??
        'zone_${DateTime.now().millisecondsSinceEpoch}';
    final siteName = attributes['SITE_NAME'] as String? ??
        attributes['NAME'] as String? ??
        'Protected Marine Zone';
    final protectionLevel = attributes['PROT_LEVEL'] as String? ??
        attributes['PROT_LVT'] as String? ??
        'No-Take Marine Reserve';
    final governance = attributes['GOV_LEVEL'] as String? ??
        attributes['GOVERNANCE'] as String? ??
        'State / Federal';
    final url = attributes['URL'] as String? ?? '';

    final ringsJson = geometry['rings'] as List<dynamic>? ?? [];
    final polygonRings = <List<LatLng>>[];

    for (final ring in ringsJson) {
      if (ring is List) {
        final points = <LatLng>[];
        for (final pt in ring) {
          if (pt is List && pt.length >= 2) {
            final lng = (pt[0] as num).toDouble();
            final lat = (pt[1] as num).toDouble();
            points.add(LatLng(lat, lng));
          }
        }
        if (points.length >= 3) {
          polygonRings.add(points);
        }
      }
    }

    return NoFishingZone(
      id: id,
      siteName: siteName,
      protectionLevel: protectionLevel,
      governance: governance,
      url: url,
      polygonRings: polygonRings,
    );
  }
}

class NoFishingZonesService {
  final http.Client _client;

  NoFishingZonesService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<NoFishingZone>> fetchZonesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    final bbox = '$minLng,$minLat,$maxLng,$maxLat';
    final uri = Uri.parse(MapLayerConfig.noaaMpaQueryUrl).replace(
      queryParameters: {
        'where': '1=1',
        'geometry': bbox,
        'geometryType': 'esriGeometryEnvelope',
        'spatialRel': 'esriSpatialRelIntersects',
        'inSR': '4326',
        'outSR': '4326',
        'outFields':
            'OBJECTID,SITE_ID,SITE_NAME,NAME,PROT_LEVEL,PROT_LVT,GOV_LEVEL,GOVERNANCE,URL',
        'returnGeometry': 'true',
        'f': 'json',
        'resultRecordCount': '100',
      },
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch No-Fishing Zones (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      return features
          .map((f) => NoFishingZone.fromJson(f as Map<String, dynamic>))
          .where((zone) => zone.polygonRings.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Could not load No-Fishing Zones: $e');
    }
  }
}

final noFishingZonesServiceProvider = Provider<NoFishingZonesService>((ref) {
  return NoFishingZonesService();
});
