import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PostcardZone {
  bool contains(double lat, double lng);
  Map<String, dynamic> toMap();
}

class CircleZone implements PostcardZone {
  final double lat;
  final double lng;
  final double radiusMeters;

  const CircleZone({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  factory CircleZone.fromMap(Map<String, dynamic> map) {
    return CircleZone(
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 100.0,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'radiusMeters': radiusMeters,
    };
  }

  @override
  bool contains(double queryLat, double queryLng) {
    return false;
  }
}

class Postcard {
  final String id;
  final String title;
  final String description;
  final String locationName;
  final String imageUrl;
  final CircleZone zone;
  final String geohash;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  const Postcard({
    required this.id,
    required this.title,
    required this.description,
    required this.locationName,
    this.imageUrl = '',
    required this.zone,
    required this.geohash,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  factory Postcard.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is DateTime) return value;
      return null;
    }

    final zoneMap = map['zone'] as Map<String, dynamic>? ?? {};

    return Postcard(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      locationName: map['locationName'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      zone: CircleZone.fromMap(zoneMap),
      geohash: map['geohash'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'locationName': locationName,
      'imageUrl': imageUrl,
      'zone': zone.toMap(),
      'geohash': geohash,
      'active': active,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  Postcard copyWith({
    String? id,
    String? title,
    String? description,
    String? locationName,
    String? imageUrl,
    CircleZone? zone,
    String? geohash,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Postcard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      locationName: locationName ?? this.locationName,
      imageUrl: imageUrl ?? this.imageUrl,
      zone: zone ?? this.zone,
      geohash: geohash ?? this.geohash,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class EarnedPostcard {
  final String postcardId;
  final DateTime earnedAt;
  final String title;

  const EarnedPostcard({
    required this.postcardId,
    required this.earnedAt,
    required this.title,
  });

  factory EarnedPostcard.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return EarnedPostcard(
      postcardId: map['postcardId'] as String? ?? docId,
      earnedAt: parseDateTime(map['earnedAt']),
      title: map['title'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postcardId': postcardId,
      'earnedAt': FieldValue.serverTimestamp(),
      'title': title,
    };
  }
}
