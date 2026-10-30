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

class LupitaLocationDetail {
  final String label;
  final String value;

  const LupitaLocationDetail({
    required this.label,
    required this.value,
  });

  factory LupitaLocationDetail.fromList(List<dynamic> list) {
    if (list.length >= 2) {
      return LupitaLocationDetail(
        label: list[0].toString(),
        value: list[1].toString(),
      );
    }
    return const LupitaLocationDetail(label: '', value: '');
  }
}

class LupitaRegulation {
  final String summary;
  final String minSize;
  final String maxSize;
  final String bagLimit;
  final String season;
  final String jurisdiction;
  final String sourceName;
  final String sourceUrl;

  const LupitaRegulation({
    required this.summary,
    required this.minSize,
    required this.maxSize,
    required this.bagLimit,
    required this.season,
    required this.jurisdiction,
    required this.sourceName,
    required this.sourceUrl,
  });

  factory LupitaRegulation.fromJson(Map<String, dynamic> json) {
    return LupitaRegulation(
      summary: json['summary'] as String? ?? '',
      minSize: json['min_size'] as String? ?? '',
      maxSize: json['max_size'] as String? ?? '',
      bagLimit: json['bag_limit'] as String? ?? '',
      season: json['season'] as String? ?? '',
      jurisdiction: json['jurisdiction'] as String? ?? '',
      sourceName: json['source_name'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
    );
  }
}

class LupitaBiteWindow {
  final DateTime? startTime;
  final DateTime? endTime;
  final double score;
  final List<String> why;

  const LupitaBiteWindow({
    this.startTime,
    this.endTime,
    required this.score,
    required this.why,
  });

  factory LupitaBiteWindow.fromJson(Map<String, dynamic> json) {
    final windowObj = json['window'] as Map<String, dynamic>?;
    DateTime? start;
    DateTime? end;
    double scoreVal = 0.0;

    if (windowObj != null) {
      final startStr = (windowObj['start'] as String?) ?? (windowObj['start_utc'] as String?);
      final endStr = (windowObj['end'] as String?) ?? (windowObj['end_utc'] as String?);
      if (startStr != null) start = DateTime.tryParse(startStr);
      if (endStr != null) end = DateTime.tryParse(endStr);
      scoreVal = (windowObj['score'] as num?)?.toDouble() ?? 0.0;
    }

    final rawWhy = json['why'] as List<dynamic>?;
    final whyList = rawWhy?.map((e) => e.toString()).toList() ?? <String>[];

    return LupitaBiteWindow(
      startTime: start,
      endTime: end,
      score: scoreVal,
      why: whyList,
    );
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
  final List<LupitaLocationDetail> locationDetails;
  final String? seaSummary;
  final LupitaBiteWindow? biteWindow;

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
    this.locationDetails = const [],
    this.seaSummary,
    this.biteWindow,
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

    final rawLocation = json['location'] as List<dynamic>?;
    final locationList = rawLocation != null
        ? rawLocation
            .whereType<List<dynamic>>()
            .map((loc) => LupitaLocationDetail.fromList(loc))
            .where((loc) => loc.label.isNotEmpty && loc.value.isNotEmpty)
            .toList()
        : <LupitaLocationDetail>[];

    final seaObj = json['sea'] as Map<String, dynamic>?;
    final seaSummary = seaObj != null ? (seaObj['summary'] as String? ?? seaObj['text'] as String?) : null;

    final timingObj = json['timing'] as Map<String, dynamic>?;
    final biteWindow = timingObj != null ? LupitaBiteWindow.fromJson(timingObj) : null;

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
      locationDetails: locationList,
      seaSummary: seaSummary,
      biteWindow: biteWindow,
    );
  }
}

class LupitaSpecies {
  final String id;
  final String name;
  final String sci;
  final String colorHex;
  final List<LupitaSpec> specs;
  final LupitaRegulation? regulations;
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
    this.regulations,
    required this.status,
    required this.message,
    required this.spotCount,
    required this.spots,
  });

  String get imageUrl =>
      'https://cdn.jsdelivr.net/gh/markeetox/lupita@data/api/v1/img/$id.png';

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

    final regObj = json['regulations'] as Map<String, dynamic>?;
    final regulations = regObj != null ? LupitaRegulation.fromJson(regObj) : null;

    final rawSpotsCount = json['spots'] is num
        ? (json['spots'] as num).toInt()
        : (json['spots_count'] as num?)?.toInt();

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
      sci: (json['sci'] as String?) ?? (json['scientific_name'] as String?) ?? '',
      colorHex: json['color'] as String? ?? '#00E5FF',
      specs: specsList,
      regulations: regulations,
      status: json['status'] as String? ?? 'ok',
      message: json['message'] as String? ?? '',
      spotCount: rawSpotsCount ?? matchingSpots.length,
      spots: matchingSpots,
    );
  }

  LupitaSpecies copyWithSpots(List<LupitaSpot> newSpots) {
    return LupitaSpecies(
      id: id,
      name: name,
      sci: sci,
      colorHex: colorHex,
      specs: specs,
      regulations: regulations,
      status: status,
      message: message,
      spotCount: newSpots.length,
      spots: newSpots,
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

  int get speciesWithPredictionsCount =>
      species.where((s) => s.spots.isNotEmpty).length;

  factory LupitaData.fromJson(Map<String, dynamic> json) {
    final rawTopSpots = json['spots'] as List<dynamic>?;
    final topSpotsList = rawTopSpots != null
        ? rawTopSpots
            .whereType<Map<String, dynamic>>()
            .map((s) => LupitaSpot.fromJson(s, ''))
            .toList()
        : <LupitaSpot>[];

    final rawSpecies = json['species'] as List<dynamic>?;
    final speciesList = rawSpecies != null
        ? rawSpecies
            .whereType<Map<String, dynamic>>()
            .map((s) => LupitaSpecies.fromJson(s, allSpots: topSpotsList))
            .toList()
        : <LupitaSpecies>[];

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
  static const String jsDelivrCatalogUrl =
      'https://cdn.jsdelivr.net/gh/markeetox/lupita@data/species_catalog.json';
  static const String rawGithubCatalogUrl =
      'https://raw.githubusercontent.com/markeetox/lupita/data/species_catalog.json';

  static const String jsDelivrFishUrl =
      'https://cdn.jsdelivr.net/gh/markeetox/lupita@data/fish.json';
  static const String rawGithubFishUrl =
      'https://raw.githubusercontent.com/markeetox/lupita/data/fish.json';

  static const String apiV1IndexUrl =
      'https://cdn.jsdelivr.net/gh/markeetox/lupita@data/api/v1/index.json';

  Future<Map<String, dynamic>?> _fetchJsonFromUrls(List<String> urls) async {
    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<LupitaData> fetchLupitaData() async {
    final catalogUrls = [
      jsDelivrCatalogUrl,
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(rawGithubCatalogUrl)}',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(rawGithubCatalogUrl)}',
      rawGithubCatalogUrl,
    ];

    final fishUrls = [
      jsDelivrFishUrl,
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(rawGithubFishUrl)}',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(rawGithubFishUrl)}',
      rawGithubFishUrl,
    ];

    final catalogJson = await _fetchJsonFromUrls(catalogUrls);
    final fishJson = await _fetchJsonFromUrls(fishUrls);

    if (catalogJson != null || fishJson != null) {
      final List<LupitaSpot> allSpots = [];
      if (fishJson != null) {
        final rawSpots = fishJson['spots'] as List<dynamic>?;
        if (rawSpots != null) {
          allSpots.addAll(
            rawSpots
                .whereType<Map<String, dynamic>>()
                .map((s) => LupitaSpot.fromJson(s, '')),
          );
        }
      }

      final Map<String, LupitaSpecies> speciesMap = {};

      if (catalogJson != null) {
        final rawCatSpecies = catalogJson['species'] as List<dynamic>?;
        if (rawCatSpecies != null) {
          for (final item in rawCatSpecies.whereType<Map<String, dynamic>>()) {
            final s = LupitaSpecies.fromJson(item, allSpots: allSpots);
            speciesMap[s.id] = s;
          }
        }
      }

      if (fishJson != null) {
        final rawFishSpecies = fishJson['species'] as List<dynamic>?;
        if (rawFishSpecies != null) {
          for (final item in rawFishSpecies.whereType<Map<String, dynamic>>()) {
            final s = LupitaSpecies.fromJson(item, allSpots: allSpots);
            if (!speciesMap.containsKey(s.id)) {
              speciesMap[s.id] = s;
            } else {
              final existing = speciesMap[s.id]!;
              final mergedSpots = s.spots.isNotEmpty ? s.spots : existing.spots;
              speciesMap[s.id] = existing.copyWithSpots(mergedSpots);
            }
          }
        }
      }

      for (final spot in allSpots) {
        if (speciesMap.containsKey(spot.speciesId)) {
          final existing = speciesMap[spot.speciesId]!;
          if (!existing.spots.any((s) => s.id == spot.id)) {
            final updatedSpots = List<LupitaSpot>.from(existing.spots)..add(spot);
            speciesMap[spot.speciesId] = existing.copyWithSpots(updatedSpots);
          }
        }
      }

      final List<LupitaSpecies> finalSpeciesList = speciesMap.values.toList();

      final version = catalogJson?['version'] as int? ?? fishJson?['version'] as int? ?? 1;
      final generatedUtc = catalogJson?['generated_utc'] as String? ?? fishJson?['generated_utc'] as String? ?? '';
      final disclaimer = catalogJson?['disclaimer'] as String? ?? fishJson?['disclaimer'] as String? ?? '';

      return LupitaData(
        version: version,
        generatedUtc: generatedUtc,
        disclaimer: disclaimer,
        species: finalSpeciesList,
        allSpots: allSpots,
      );
    }

    try {
      final v1Response = await http.get(Uri.parse(apiV1IndexUrl)).timeout(const Duration(seconds: 10));
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
                final specResp = await http.get(Uri.parse(specDetailUrl)).timeout(const Duration(seconds: 6));
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
          allSpots: speciesList.expand((s) => s.spots).toList(),
        );
      }
    } catch (_) {}

    throw Exception('Failed to load Lupita fish data from catalog, fish predictions, or fallback API index.');
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
