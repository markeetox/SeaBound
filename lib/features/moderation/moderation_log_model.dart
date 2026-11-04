import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationLog {
  final String id;
  final String adminId;
  final String contentType;
  final String contentId;
  final String previousStatus;
  final String newStatus;
  final String reason;
  final DateTime createdAt;

  const ModerationLog({
    required this.id,
    required this.adminId,
    required this.contentType,
    required this.contentId,
    required this.previousStatus,
    required this.newStatus,
    required this.reason,
    required this.createdAt,
  });

  factory ModerationLog.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return ModerationLog(
      id: map['id'] as String? ?? docId,
      adminId: map['adminId'] as String? ?? '',
      contentType: map['contentType'] as String? ?? '',
      contentId: map['contentId'] as String? ?? '',
      previousStatus: map['previousStatus'] as String? ?? 'active',
      newStatus: map['newStatus'] as String? ?? 'active',
      reason: map['reason'] as String? ?? '',
      createdAt: map['createdAt'] != null ? parseDateTime(map['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'contentType': contentType,
      'contentId': contentId,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
