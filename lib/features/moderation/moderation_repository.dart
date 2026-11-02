import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'report_model.dart';

enum ReportSubmissionStatus {
  success,
  submittedReceiptFailed,
  alreadyReportedLocally,
  failure,
}

class ReportSubmissionResult {
  final ReportSubmissionStatus status;
  final String? errorMessage;

  const ReportSubmissionResult._(this.status, [this.errorMessage]);

  factory ReportSubmissionResult.success() =>
      const ReportSubmissionResult._(ReportSubmissionStatus.success);

  factory ReportSubmissionResult.submittedReceiptFailed(String message) =>
      ReportSubmissionResult._(ReportSubmissionStatus.submittedReceiptFailed, message);

  factory ReportSubmissionResult.alreadyReported() =>
      const ReportSubmissionResult._(ReportSubmissionStatus.alreadyReportedLocally);

  factory ReportSubmissionResult.failure(String message) =>
      ReportSubmissionResult._(ReportSubmissionStatus.failure, message);

  bool get isSuccess => status == ReportSubmissionStatus.success;
  bool get isSubmittedReceiptFailed => status == ReportSubmissionStatus.submittedReceiptFailed;
  bool get isAlreadyReported => status == ReportSubmissionStatus.alreadyReportedLocally;
}

typedef ReportWriter = Future<void> Function(String reportId, Map<String, dynamic> data);

class ModerationRepository {
  final FirebaseFirestore? _firestore;
  final SharedPreferences? _prefs;
  final ReportWriter? _reportWriter;
  static const String _reportedKeyPrefix = 'seabound_reported_item_';

  ModerationRepository({
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
    ReportWriter? reportWriter,
  })  : _firestore = firestore,
        _prefs = prefs,
        _reportWriter = reportWriter;

  bool hasReportedLocally(String reportId) {
    if (_prefs == null) return false;
    return _prefs.getBool('$_reportedKeyPrefix$reportId') ?? false;
  }

  Future<ReportSubmissionResult> submitReport(ReportItem report) async {
    // 1. Check local confirmed receipt first
    if (hasReportedLocally(report.id)) {
      return ReportSubmissionResult.alreadyReported();
    }

    try {
      // 2. Direct create-only write (via custom report writer or standard firestore instance)
      if (_reportWriter != null) {
        await _reportWriter(report.id, report.toMap());
      } else if (_firestore != null) {
        await _firestore.collection('reports').doc(report.id).set(report.toMap());
      } else {
        await FirebaseFirestore.instance.collection('reports').doc(report.id).set(report.toMap());
      }

      // 3. ONLY record receipt upon verified success
      if (_prefs != null) {
        try {
          final saved = await _prefs.setBool('$_reportedKeyPrefix${report.id}', true);
          if (!saved) {
            return ReportSubmissionResult.submittedReceiptFailed(
              'Your report was submitted successfully, but local receipt storage could not be saved.',
            );
          }
        } catch (prefsError) {
          return ReportSubmissionResult.submittedReceiptFailed(
            'Your report was submitted successfully, but local receipt storage failed ($prefsError).',
          );
        }
      }
      return ReportSubmissionResult.success();
    } on FirebaseException catch (e) {
      // Never record receipt on failure
      // Do not assume permission-denied is a duplicate
      return ReportSubmissionResult.failure(
        e.code == 'permission-denied'
            ? 'Report submission was rejected. Please ensure the content is active and all fields are valid.'
            : (e.message ?? 'Submission failed. Please try again later.'),
      );
    } catch (e) {
      return ReportSubmissionResult.failure('An unexpected error occurred: $e');
    }
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).asData?.value;
  return ModerationRepository(
    firestore: FirebaseFirestore.instance,
    prefs: prefs,
  );
});
