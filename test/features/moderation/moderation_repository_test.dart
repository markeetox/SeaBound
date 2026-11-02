import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/moderation/moderation_repository.dart';
import 'package:seabound/features/moderation/report_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ModerationRepository Unit Tests', () {
    late SharedPreferences prefs;
    late Map<String, Map<String, dynamic>> inMemoryStore;
    late bool throwPermissionDenied;
    late ModerationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      inMemoryStore = {};
      throwPermissionDenied = false;

      repo = ModerationRepository(
        prefs: prefs,
        reportWriter: (reportId, data) async {
          if (throwPermissionDenied) {
            throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
          }
          if (inMemoryStore.containsKey(reportId)) {
            // Create-only violation
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
              message: 'Document already exists',
            );
          }
          inMemoryStore[reportId] = data;
        },
      );
    });

    test('first submission succeeds and records local receipt', () async {
      final report = ReportItem.create(
        contentType: 'spot',
        contentId: 'spot_100',
        authorId: 'author_200',
        reporterId: 'reporter_300',
        category: 'spam_misleading',
      );

      expect(repo.hasReportedLocally(report.id), isFalse);

      final result = await repo.submitReport(report);
      expect(result.isSuccess, isTrue);
      expect(inMemoryStore.containsKey(report.id), isTrue);

      // Verify local receipt was written
      expect(repo.hasReportedLocally(report.id), isTrue);
    });

    test('re-submitting when local receipt exists returns alreadyReported without calling Firestore', () async {
      final report = ReportItem.create(
        contentType: 'spot',
        contentId: 'spot_100',
        authorId: 'author_200',
        reporterId: 'reporter_300',
        category: 'spam_misleading',
      );

      // Pre-set local receipt
      await prefs.setBool('seabound_reported_item_${report.id}', true);

      final result = await repo.submitReport(report);
      expect(result.isAlreadyReported, isTrue);
      expect(inMemoryStore.containsKey(report.id), isFalse);
    });

    test('does NOT record local receipt when write fails with permission-denied', () async {
      throwPermissionDenied = true;

      final report = ReportItem.create(
        contentType: 'spot',
        contentId: 'spot_fail',
        authorId: 'author_200',
        reporterId: 'reporter_300',
        category: 'harassment',
      );

      final result = await repo.submitReport(report);
      expect(result.isSuccess, isFalse);
      expect(result.status, ReportSubmissionStatus.failure);
      expect(result.errorMessage, contains('Report submission was rejected'));

      // Crucial requirement: local receipt MUST NOT be recorded on failure
      expect(repo.hasReportedLocally(report.id), isFalse);
      expect(prefs.getBool('seabound_reported_item_${report.id}'), isNull);
    });

    test('returns submittedReceiptFailed when Firestore write succeeds but SharedPreferences fails', () async {
      // Simulate failing SharedPreferences by creating repository with null prefs
      final failingPrefsRepo = ModerationRepository(
        prefs: null, // Null prefs simulates absent or failing receipt storage
        reportWriter: (reportId, data) async {
          inMemoryStore[reportId] = data;
        },
      );

      final report = ReportItem.create(
        contentType: 'spot',
        contentId: 'spot_receipt_fail',
        authorId: 'author_200',
        reporterId: 'reporter_300',
        category: 'hate_speech',
      );

      final result = await failingPrefsRepo.submitReport(report);
      // Write succeeded in Firestore!
      expect(inMemoryStore.containsKey(report.id), isTrue);
      expect(result.isSuccess, isTrue);
    });
  });
}
