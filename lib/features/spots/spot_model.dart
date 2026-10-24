import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Spot {
  final String id;
  final String userId;
  final String authorName;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> species;
  final bool isTrip;
  final List<Map<String, double>> trailPoints;
  final DateTime? createdAt;

  const Spot({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.species,
    this.isTrip = false,
    this.trailPoints = const [],
    this.createdAt,
  });

  List<LatLng> get latLngTrailPoints {
    return trailPoints
        .map((p) => LatLng(p['lat'] ?? 0.0, p['lng'] ?? 0.0))
        .toList();
  }

  factory Spot.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value is DateTime) {
        return value;
      }
      return DateTime.now();
    }

    final trailRaw = map['trailPoints'] as List<dynamic>?;
    final parsedTrail = trailRaw != null
        ? trailRaw.map((item) {
            if (item is Map) {
              final lat = (item['lat'] as num?)?.toDouble() ?? 0.0;
              final lng = (item['lng'] as num?)?.toDouble() ?? 0.0;
              return {'lat': lat, 'lng': lng};
            }
            return <String, double>{};
          }).where((m) => m.isNotEmpty).toList()
        : const <Map<String, double>>[];

    return Spot(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Captain',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      species: (map['species'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isTrip: map['isTrip'] as bool? ?? false,
      trailPoints: parsedTrail,
      createdAt: map['createdAt'] != null ? parseDateTime(map['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'authorName': authorName,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'species': species,
      'isTrip': isTrip,
      'trailPoints': trailPoints,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  Spot copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    List<String>? species,
    bool? isTrip,
    List<Map<String, double>>? trailPoints,
    DateTime? createdAt,
  }) {
    return Spot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      species: species ?? this.species,
      isTrip: isTrip ?? this.isTrip,
      trailPoints: trailPoints ?? this.trailPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Spot &&
        other.id == id &&
        other.userId == userId &&
        other.authorName == authorName &&
        other.name == name &&
        other.description == description &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        _listEquals(other.species, species);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      authorName,
      name,
      description,
      latitude,
      longitude,
      Object.hashAll(species),
    );
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
