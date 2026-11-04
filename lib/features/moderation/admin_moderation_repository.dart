import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'moderation_log_model.dart';
import 'report_model.dart';

class AdminModerationRepository {
  final FirebaseFirestore _firestore;

  AdminModerationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get _logsRef =>
      _firestore.collection('moderation_logs');

  Stream<List<ReportItem>> getReportsStream({String? statusFilter}) {
    Query<Map<String, dynamic>> query = _reportsRef;
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReportItem.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<Map<String, int>> getReportCountsStream() {
    return _reportsRef.snapshots().map((snapshot) {
      int pending = 0;
      int underReview = 0;
      int resolved = 0;
      int dismissed = 0;

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'pending';
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'under_review':
            underReview++;
            break;
          case 'resolved':
            resolved++;
            break;
          case 'dismissed':
            dismissed++;
            break;
        }
      }
      return {
        'pending': pending,
        'under_review': underReview,
        'resolved': resolved,
        'dismissed': dismissed,
        'total': snapshot.docs.length,
      };
    });
  }

  Stream<List<ModerationLog>> getModerationLogsStream() {
    return _logsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ModerationLog.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<ReportItem?> getReportById(String reportId) async {
    final doc = await _reportsRef.doc(reportId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReportItem.fromMap(doc.data()!, doc.id);
  }

  Future<void> markUnderReview(String reportId) async {
    await _reportsRef.doc(reportId).update({
      'status': 'under_review',
    });
  }

  Future<void> resolveReport({
    required String reportId,
    required String adminId,
    required String resolutionNotes,
  }) async {
    await _reportsRef.doc(reportId).update({
      'status': 'resolved',
      'resolvedBy': adminId,
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolutionNotes': resolutionNotes,
    });
  }

  Future<void> dismissReport({
    required String reportId,
    required String adminId,
    required String resolutionNotes,
  }) async {
    await _reportsRef.doc(reportId).update({
      'status': 'dismissed',
      'resolvedBy': adminId,
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolutionNotes': resolutionNotes,
    });
  }

  Future<void> moderateContent({
    required String contentType,
    required String contentId,
    required String previousStatus,
    required String newStatus,
    required String reason,
    required String adminId,
  }) async {
    final logRef = _logsRef.doc();
    final logId = logRef.id;

    final batch = _firestore.batch();

    // 1. Audit log record
    batch.set(logRef, {
      'id': logId,
      'adminId': adminId,
      'contentType': contentType,
      'contentId': contentId,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Content record mutation coupled to logId
    final contentRef = contentType == 'spot'
        ? _firestore.collection('spots').doc(contentId)
        : _firestore.collection('trips').doc(contentId);

    batch.update(contentRef, {
      'moderationStatus': newStatus,
      'moderationLogId': logId,
    });

    await batch.commit();
  }

  Future<Map<String, dynamic>?> fetchTargetContent({
    required String contentType,
    required String contentId,
  }) async {
    final collection = contentType == 'spot'
        ? 'spots'
        : contentType == 'trip'
            ? 'trips'
            : 'users';
    final doc = await _firestore.collection(collection).doc(contentId).get();
    if (!doc.exists) return null;
    return doc.data();
  }
}

final adminModerationRepositoryProvider = Provider<AdminModerationRepository>((ref) {
  return AdminModerationRepository();
});
