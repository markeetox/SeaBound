import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final String locationName;
  final List<String> species;
  final String notes;
  final List<String> sharedWith;
  final List<String> likedBy;
  final List<String> dislikedBy;
  final DateTime? createdAt;

  const Trip({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.locationName,
    required this.species,
    required this.notes,
    this.sharedWith = const [],
    this.likedBy = const [],
    this.dislikedBy = const [],
    this.createdAt,
  });

  int get likeCount => likedBy.length;
  int get dislikeCount => dislikedBy.length;

  bool isLikedBy(String uid) => likedBy.contains(uid);
  bool isDislikedBy(String uid) => dislikedBy.contains(uid);

  factory Trip.fromMap(Map<String, dynamic> map, String documentId) {
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

    return Trip(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      date: parseDateTime(map['date']),
      locationName: map['locationName'] as String? ?? '',
      species: (map['species'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: map['notes'] as String? ?? '',
      sharedWith: (map['sharedWith'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      likedBy: (map['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dislikedBy: (map['dislikedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: map['createdAt'] != null ? parseDateTime(map['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'locationName': locationName,
      'species': species,
      'notes': notes,
      'sharedWith': sharedWith,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  Trip copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    String? locationName,
    List<String>? species,
    String? notes,
    List<String>? sharedWith,
    List<String>? likedBy,
    List<String>? dislikedBy,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      locationName: locationName ?? this.locationName,
      species: species ?? this.species,
      notes: notes ?? this.notes,
      sharedWith: sharedWith ?? this.sharedWith,
      likedBy: likedBy ?? this.likedBy,
      dislikedBy: dislikedBy ?? this.dislikedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.date == date &&
        other.locationName == locationName &&
        _listEquals(other.species, species) &&
        other.notes == notes &&
        _listEquals(other.sharedWith, sharedWith) &&
        _listEquals(other.likedBy, likedBy) &&
        _listEquals(other.dislikedBy, dislikedBy);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      date,
      locationName,
      Object.hashAll(species),
      notes,
      Object.hashAll(sharedWith),
      Object.hashAll(likedBy),
      Object.hashAll(dislikedBy),
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
