import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class LupitaSpec {
  final String label;
  final String value;

  const LupitaSpec({
    required this.label,
    required this.value,
  });

  factory LupitaSpec.fromList(List<dynamic> list) {
    if (list.length >= 2) {
      return LupitaSpec(
        label: list[0].toString(),
        value: list[1].toString(),
      );
    }
    return const LupitaSpec(label: '', value: '');
  }
}

class LupitaReason {
  final String category;
  final String text;

  const LupitaReason({
    required this.category,
    required this.text,
  });

  factory LupitaReason.fromList(List<dynamic> list) {
    if (list.length >= 2) {
      return LupitaReason(
        category: list[0].toString(),
        text: list[1].toString(),
      );
    }
    return const LupitaReason(category: '', text: '');
  }
}

class LupitaSpot {
  final String id;
  final String speciesId;
  final String title;
  final double score;
  final String confidence;
  final double dataCoverage;
  final double latitude;
  final double longitude;
  final List<LupitaReason> reasons;
  final String? seaSummary;

  const LupitaSpot({
    required this.id,
    required this.speciesId,
    required this.title,
    required this.score,
    required this.confidence,
    required this.dataCoverage,
    required this.latitude,
    required this.longitude,
    required this.reasons,
    this.seaSummary,
  });

  factory LupitaSpot.fromJson(Map<String, dynamic> json, String defaultSpeciesId) {
    final coords = json['coords'] as List<dynamic>?;
    final lng = coords != null && coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
    final lat = coords != null && coords.length >= 2 ? (coords[1] as num).toDouble() : 0.0;

    final rawReasons = json['reasons'] as List<dynamic>?;
    final reasonsList = rawReasons != null
        ? rawReasons
            .whereType<List<dynamic>>()
            .map((r) => LupitaReason.fromList(r))
            .where((r) => r.text.isNotEmpty)
            .toList()
        : <LupitaReason>[];

    final seaObj = json['sea'] as Map<String, dynamic>?;
    final seaSummary = seaObj != null ? (seaObj['summary'] as String?) : null;

    return LupitaSpot(
      id: json['id'] as String? ?? '',
      speciesId: json['species'] as String? ?? defaultSpeciesId,
      title: json['title'] as String? ?? 'Fish Spot',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      confidence: json['confidence'] as String? ?? 'Medium',
      dataCoverage: (json['data_coverage'] as num?)?.toDouble() ?? 1.0,
      latitude: lat,
      longitude: lng,
      reasons: reasonsList,
      seaSummary: seaSummary,
    );
  }
}

class LupitaSpecies {
  final String id;
  final String name;
  final String sci;
  final String colorHex;
  final List<LupitaSpec> specs;
  final String status;
  final String message;
  final int spotCount;
  final List<LupitaSpot> spots;

  const LupitaSpecies({
    required this.id,
    required this.name,
    required this.sci,
    required this.colorHex,
    required this.specs,
    required this.status,
    required this.message,
    required this.spotCount,
    required this.spots,
  });

  factory LupitaSpecies.fromJson(Map<String, dynamic> json, {List<LupitaSpot> allSpots = const []}) {
    final speciesId = json['id'] as String? ?? '';
    final rawSpecs = json['specs'] as List<dynamic>?;
    final specsList = rawSpecs != null
        ? rawSpecs
            .whereType<List<dynamic>>()
            .map((s) => LupitaSpec.fromList(s))
            .where((s) => s.label.isNotEmpty)
            .toList()
        : <LupitaSpec>[];

    // Read spot count if stored as num, or count matching spots
    final rawSpotsCount = json['spots'] is num
        ? (json['spots'] as num).toInt()
        : (json['spots_count'] as num?)?.toInt();

    // Direct spots array inside species element (if any) or filter from allSpots
    List<LupitaSpot> matchingSpots = [];
    if (json['spots'] is List) {
      final rawSpots = json['spots'] as List<dynamic>;
      matchingSpots = rawSpots
          .whereType<Map<String, dynamic>>()
          .map((s) => LupitaSpot.fromJson(s, speciesId))
          .toList();
    } else {
      matchingSpots = allSpots.where((s) => s.speciesId == speciesId).toList();
    }

    return LupitaSpecies(
      id: speciesId,
      name: json['name'] as String? ?? speciesId,
      sci: json['sci'] as String? ?? '',
      colorHex: json['color'] as String? ?? '#00E5FF',
      specs: specsList,
      status: json['status'] as String? ?? 'ok',
      message: json['message'] as String? ?? '',
      spotCount: rawSpotsCount ?? matchingSpots.length,
      spots: matchingSpots,
    );
  }
}

class LupitaData {
  final int version;
  final String generatedUtc;
  final String disclaimer;
  final List<LupitaSpecies> species;
  final List<LupitaSpot> allSpots;

  const LupitaData({
    required this.version,
    required this.generatedUtc,
    required this.disclaimer,
    required this.species,
    this.allSpots = const [],
  });

  factory LupitaData.fromJson(Map<String, dynamic> json) {
    // Parse top-level spots list
    final rawTopSpots = json['spots'] as List<dynamic>?;
    final topSpotsList = rawTopSpots != null
        ? rawTopSpots
            .whereType<Map<String, dynamic>>()
            .map((s) => LupitaSpot.fromJson(s, ''))
            .toList()
        : <LupitaSpot>[];

    // Parse species list
    final rawSpecies = json['species'] as List<dynamic>?;
    final speciesList = rawSpecies != null
        ? rawSpecies
            .whereType<Map<String, dynamic>>()
            .map((s) => LupitaSpecies.fromJson(s, allSpots: topSpotsList))
            .toList()
        : <LupitaSpecies>[];

    // If topSpotsList was empty, gather spots from species
    final finalAllSpots = topSpotsList.isNotEmpty
        ? topSpotsList
        : speciesList.expand((s) => s.spots).toList();

    return LupitaData(
      version: json['version'] as int? ?? 1,
      generatedUtc: json['generated_utc'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '',
      species: speciesList,
      allSpots: finalAllSpots,
    );
  }
}

class LupitaService {
  static const String jsDelivrUrl =
      'https://cdn.jsdelivr.net/gh/markeetox/lupita@data/fish.json';
  static const String rawGithubUrl =
      'https://raw.githubusercontent.com/markeetox/lupita/data/fish.json';
  static const String apiV1IndexUrl =
      'https://cdn.jsdelivr.net/gh/markeetox/lupita@data/api/v1/index.json';

  Future<LupitaData> fetchLupitaData() async {
    final urls = [
      jsDelivrUrl,
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(rawGithubUrl)}',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(rawGithubUrl)}',
      rawGithubUrl,
    ];

    Object? lastError;

    for (final url in urls) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body) as Map<String, dynamic>;
          return LupitaData.fromJson(decoded);
        }
      } catch (e) {
        lastError = e;
      }
    }

    // Fallback: try API v1 index endpoint
    try {
      final v1Response = await http
          .get(Uri.parse(apiV1IndexUrl))
          .timeout(const Duration(seconds: 10));

      if (v1Response.statusCode == 200) {
        final v1Decoded = json.decode(v1Response.body) as Map<String, dynamic>;
        final rawSpecies = v1Decoded['species'] as List<dynamic>?;
        final speciesList = <LupitaSpecies>[];

        if (rawSpecies != null) {
          for (final item in rawSpecies.whereType<Map<String, dynamic>>()) {
            final speciesId = item['id'] as String? ?? '';
            final detailPath = item['details'] as String?;

            List<LupitaSpot> spotsList = [];
            if (detailPath != null && detailPath.isNotEmpty) {
              try {
                final specDetailUrl =
                    'https://cdn.jsdelivr.net/gh/markeetox/lupita@data/api/v1/$detailPath';
                final specResp = await http
                    .get(Uri.parse(specDetailUrl))
                    .timeout(const Duration(seconds: 6));
                if (specResp.statusCode == 200) {
                  final specData = json.decode(specResp.body) as Map<String, dynamic>;
                  final rawSpots = specData['spots'] as List<dynamic>?;
                  if (rawSpots != null) {
                    spotsList = rawSpots
                        .whereType<Map<String, dynamic>>()
                        .map((s) => LupitaSpot.fromJson(s, speciesId))
                        .toList();
                  }
                }
              } catch (_) {}
            }

            speciesList.add(
              LupitaSpecies(
                id: speciesId,
                name: item['name'] as String? ?? speciesId,
                sci: item['scientific_name'] as String? ?? '',
                colorHex: item['color'] as String? ?? '#00E5FF',
                specs: const [],
                status: item['status'] as String? ?? 'ok',
                message: item['message'] as String? ?? '',
                spotCount: (item['area_count'] as num?)?.toInt() ?? spotsList.length,
                spots: spotsList,
              ),
            );
          }
        }

        return LupitaData(
          version: v1Decoded['api_version'] as int? ?? 1,
          generatedUtc: v1Decoded['generated_utc'] as String? ?? '',
          disclaimer: v1Decoded['disclaimer'] as String? ?? '',
          species: speciesList,
        );
      }
    } catch (e) {
      lastError = e;
    }

    throw Exception('Failed to load Lupita fish data: $lastError');
  }
}

final lupitaServiceProvider = Provider<LupitaService>((ref) {
  return LupitaService();
});

final lupitaDataProvider = FutureProvider<LupitaData>((ref) async {
  final service = ref.watch(lupitaServiceProvider);
  return service.fetchLupitaData();
});

class SelectedLupitaSpeciesNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectSpecies(String? speciesId) {
    state = speciesId;
  }
}

final selectedLupitaSpeciesIdProvider =
    NotifierProvider<SelectedLupitaSpeciesNotifier, String?>(
  SelectedLupitaSpeciesNotifier.new,
);

final selectedLupitaSpeciesSpotsProvider = Provider<List<LupitaSpot>>((ref) {
  final dataAsync = ref.watch(lupitaDataProvider);
  final selectedId = ref.watch(selectedLupitaSpeciesIdProvider);

  return dataAsync.maybeWhen(
    data: (lupitaData) {
      if (selectedId == null || selectedId.isEmpty) {
        return lupitaData.allSpots;
      }
      return lupitaData.allSpots
          .where((spot) => spot.speciesId == selectedId)
          .toList();
    },
    orElse: () => const [],
  );
});
