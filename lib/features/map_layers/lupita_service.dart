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

  factory LupitaSpecies.fromJson(Map<String, dynamic> json) {
    final speciesId = json['id'] as String? ?? '';
    final rawSpecs = json['specs'] as List<dynamic>?;
    final specsList = rawSpecs != null
        ? rawSpecs
            .whereType<List<dynamic>>()
            .map((s) => LupitaSpec.fromList(s))
            .where((s) => s.label.isNotEmpty)
            .toList()
        : <LupitaSpec>[];

    final rawSpots = json['spots'] as List<dynamic>?;
    final spotsList = rawSpots != null
        ? rawSpots
            .whereType<Map<String, dynamic>>()
            .map((s) => LupitaSpot.fromJson(s, speciesId))
            .toList()
        : <LupitaSpot>[];

    return LupitaSpecies(
      id: speciesId,
      name: json['name'] as String? ?? speciesId,
      sci: json['sci'] as String? ?? '',
      colorHex: json['color'] as String? ?? '#00E5FF',
      specs: specsList,
      status: json['status'] as String? ?? 'ok',
      message: json['message'] as String? ?? '',
      spotCount: (json['spots_count'] as num?)?.toInt() ?? spotsList.length,
      spots: spotsList,
    );
  }
}

class LupitaData {
  final int version;
  final String generatedUtc;
  final String disclaimer;
  final List<LupitaSpecies> species;

  const LupitaData({
    required this.version,
    required this.generatedUtc,
    required this.disclaimer,
    required this.species,
  });

  factory LupitaData.fromJson(Map<String, dynamic> json) {
    final rawSpecies = json['species'] as List<dynamic>?;
    final speciesList = rawSpecies != null
        ? rawSpecies
            .whereType<Map<String, dynamic>>()
            .map((s) => LupitaSpecies.fromJson(s))
            .toList()
        : <LupitaSpecies>[];

    return LupitaData(
      version: json['version'] as int? ?? 1,
      generatedUtc: json['generated_utc'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '',
      species: speciesList,
    );
  }
}

class LupitaService {
  static const String dataUrl =
      'https://raw.githubusercontent.com/markeetox/lupita/data/fish.json';

  Future<LupitaData> fetchLupitaData() async {
    final urls = [
      dataUrl,
      'https://corsproxy.io/?${Uri.encodeComponent(dataUrl)}',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(dataUrl)}',
    ];

    Object? lastError;

    for (final url in urls) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: const {
                'Cache-Control': 'no-cache, no-store, must-revalidate',
                'Pragma': 'no-cache',
                'Expires': '0',
              },
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body) as Map<String, dynamic>;
          return LupitaData.fromJson(decoded);
        }
      } catch (e) {
        lastError = e;
      }
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
        return lupitaData.species.expand((s) => s.spots).toList();
      }
      final species = lupitaData.species.firstWhere(
        (s) => s.id == selectedId,
        orElse: () => lupitaData.species.isNotEmpty
            ? lupitaData.species.first
            : const LupitaSpecies(
                id: '',
                name: '',
                sci: '',
                colorHex: '#00E5FF',
                specs: [],
                status: 'ok',
                message: '',
                spotCount: 0,
                spots: [],
              ),
      );
      return species.spots;
    },
    orElse: () => const [],
  );
});
