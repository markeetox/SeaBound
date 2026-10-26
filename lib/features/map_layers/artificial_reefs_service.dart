import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/map_layer_config.dart';

class ArtificialReefPoint {
  final String id;
  final String reefName;
  final String? primaryMaterial;
  final String? waterDepthFt;
  final String? deploymentDate;
  final String? countyAgency;
  final double latitude;
  final double longitude;

  const ArtificialReefPoint({
    required this.id,
    required this.reefName,
    this.primaryMaterial,
    this.waterDepthFt,
    this.deploymentDate,
    this.countyAgency,
    required this.latitude,
    required this.longitude,
  });

  factory ArtificialReefPoint.fromGeoJson(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final geom = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coords = (geom['coordinates'] as List?)?.cast<num>() ?? [0, 0];

    final reefName = props['Reef_Name']?.toString().trim() ??
        props['REEF_NAME']?.toString().trim() ??
        'Artificial Reef';

    final material = props['Primary_Material']?.toString().trim() ??
        props['MATERIAL']?.toString().trim();

    final depth = props['Water_Depth']?.toString().trim() ??
        props['DEPTH']?.toString().trim();

    final date = props['Deployment_Date']?.toString().trim() ??
        props['DEPLOY_DATE']?.toString().trim();

    final county = props['County']?.toString().trim() ??
        props['COUNTY']?.toString().trim();

    final id = feature['id']?.toString() ??
        props['OBJECTID']?.toString() ??
        '${coords[1]}_${coords[0]}';

    return ArtificialReefPoint(
      id: id,
      reefName: reefName.isNotEmpty ? reefName : 'Artificial Reef',
      primaryMaterial: (material != null && material.isNotEmpty) ? material : null,
      waterDepthFt: (depth != null && depth.isNotEmpty && depth != '0') ? depth : null,
      deploymentDate: (date != null && date.isNotEmpty) ? date : null,
      countyAgency: (county != null && county.isNotEmpty) ? county : null,
      latitude: coords[1].toDouble(),
      longitude: coords[0].toDouble(),
    );
  }
}

class ReefsCacheEntry {
  final String key;
  final List<ArtificialReefPoint> points;
  final DateTime fetchedAt;

  ReefsCacheEntry({
    required this.key,
    required this.points,
    required this.fetchedAt,
  });

  bool get isValid => DateTime.now().difference(fetchedAt).inMinutes < 10;
}

class ArtificialReefsService {
  final http.Client _client;
  static final Map<String, ReefsCacheEntry> _cache = {};

  ArtificialReefsService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<ArtificialReefPoint>> fetchReefsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    final cacheKey =
        '${minLat.toStringAsFixed(2)},${maxLat.toStringAsFixed(2)},${minLng.toStringAsFixed(2)},${maxLng.toStringAsFixed(2)}';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.points;
    }

    final bboxParam = '$minLng,$minLat,$maxLng,$maxLat';

    final uri = Uri.parse(
      '${MapLayerConfig.fwcArtificialReefsQueryUrl}?geometry=$bboxParam&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=*&returnGeometry=true&f=geojson&resultRecordCount=1000',
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load artificial reef data (${response.statusCode})');
    }

    final Map<String, dynamic> decoded = json.decode(response.body);
    final features = (decoded['features'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final points = features.map((f) => ArtificialReefPoint.fromGeoJson(f)).toList();

    _cache[cacheKey] = ReefsCacheEntry(
      key: cacheKey,
      points: points,
      fetchedAt: DateTime.now(),
    );

    return points;
  }
}

final artificialReefsServiceProvider = Provider<ArtificialReefsService>((ref) {
  return ArtificialReefsService();
});
