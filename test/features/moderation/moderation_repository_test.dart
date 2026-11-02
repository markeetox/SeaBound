import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/moderation/moderation_repository.dart';
import 'package:seabound/features/moderation/report_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> store;
  final bool shouldThrowPermissionDenied;

  FakeCollectionReference(this.store, {this.shouldThrowPermissionDenied = false});

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReference(store, path!, shouldThrowPermissionDenied: shouldThrowPermissionDenied);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> store;
  final String docId;
  final bool shouldThrowPermissionDenied;

  FakeDocumentReference(this.store, this.docId, {this.shouldThrowPermissionDenied = false});

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (shouldThrowPermissionDenied) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    }
    if (store.containsKey(docId)) {
      // Create-only violation
      throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied', message: 'Document already exists');
    }
    store[docId] = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> store = {};
  bool throwPermissionDenied = false;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(store, shouldThrowPermissionDenied: throwPermissionDenied);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ModerationRepository Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SharedPreferences prefs;
    late ModerationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      fakeFirestore = FakeFirebaseFirestore();
      repo = ModerationRepository(firestore: fakeFirestore, prefs: prefs);
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
      expect(fakeFirestore.store.containsKey(report.id), isTrue);

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
      expect(fakeFirestore.store.containsKey(report.id), isFalse);
    });

    test('does NOT record local receipt when write fails with permission-denied', () async {
      fakeFirestore.throwPermissionDenied = true;

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
  });
}
