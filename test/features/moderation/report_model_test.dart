import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/moderation/report_model.dart';

void main() {
  group('ReportIdValidator Unit Tests', () {
    test('generates valid length-prefixed ID for spot', () {
      final id = ReportIdValidator.generate(
        contentType: 'spot',
        contentId: 'spot123',
        reporterId: 'user456',
      );
      expect(id, 'spot_7_spot123_user456');
    });

    test('generates valid length-prefixed ID when contentId has underscores and colons', () {
      final id = ReportIdValidator.generate(
        contentType: 'spot',
        contentId: 'reef:key_biscayne:42',
        reporterId: 'user_999',
      );
      // 'reef:key_biscayne:42'.length is 20
      expect(id, 'spot_20_reef:key_biscayne:42_user_999');
    });

    test('rejects invalid content types', () {
      expect(
        () => ReportIdValidator.generate(
          contentType: 'comment',
          contentId: '123',
          reporterId: 'user1',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty contentId or reporterId', () {
      expect(
        () => ReportIdValidator.generate(
          contentType: 'spot',
          contentId: '',
          reporterId: 'user1',
        ),
        throwsArgumentError,
      );
      expect(
        () => ReportIdValidator.generate(
          contentType: 'spot',
          contentId: '123',
          reporterId: '',
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-ASCII or unsafe characters', () {
      expect(
        () => ReportIdValidator.generate(
          contentType: 'spot',
          contentId: 'spot with spaces',
          reporterId: 'user1',
        ),
        throwsArgumentError,
      );
      expect(
        () => ReportIdValidator.generate(
          contentType: 'spot',
          contentId: 'spot#123!',
          reporterId: 'user1',
        ),
        throwsArgumentError,
      );
      expect(
        () => ReportIdValidator.generate(
          contentType: 'spot',
          contentId: 'spot_🎣',
          reporterId: 'user1',
        ),
        throwsArgumentError,
      );
    });

    test('validates maximum boundary length constraints', () {
      final max128 = 'a' * 128;
      final id = ReportIdValidator.generate(
        contentType: 'spot',
        contentId: max128,
        reporterId: 'u' * 50,
      );
      expect(id.length, lessThanOrEqualTo(ReportIdValidator.maxCompositeIdLength));

      final oversized = 'a' * 129;
      expect(
        () => ReportIdValidator.generate(
          contentType: 'spot',
          contentId: oversized,
          reporterId: 'user1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ReportItem Model Serialization Tests', () {
    test('creates report with valid categories and default pending status', () {
      final report = ReportItem.create(
        contentType: 'spot',
        contentId: 'spot_1',
        authorId: 'author_9',
        reporterId: 'reporter_7',
        category: 'illegal_activity',
        explanation: 'Fishing in a protected marine zone.',
      );

      expect(report.id, 'spot_6_spot_1_reporter_7');
      expect(report.status, 'pending');
      expect(report.category, 'illegal_activity');
      expect(report.explanation, 'Fishing in a protected marine zone.');

      final map = report.toMap();
      expect(map['id'], report.id);
      expect(map['contentType'], 'spot');
      expect(map['contentId'], 'spot_1');
      expect(map['authorId'], 'author_9');
      expect(map['reporterId'], 'reporter_7');
      expect(map['category'], 'illegal_activity');
      expect(map['status'], 'pending');
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('rejects invalid category', () {
      expect(
        () => ReportItem.create(
          contentType: 'spot',
          contentId: 's1',
          authorId: 'a1',
          reporterId: 'r1',
          category: 'invalid_category_xyz',
        ),
        throwsArgumentError,
      );
    });

    test('rejects explanation exceeding 300 characters', () {
      expect(
        () => ReportItem.create(
          contentType: 'spot',
          contentId: 's1',
          authorId: 'a1',
          reporterId: 'r1',
          category: 'other',
          explanation: 'a' * 301,
        ),
        throwsArgumentError,
      );
    });

    test('ReportItem.fromMap deserializes all fields correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'spot_2_s1_r1',
        'contentType': 'spot',
        'contentId': 's1',
        'authorId': 'a1',
        'reporterId': 'r1',
        'category': 'offensive_content',
        'explanation': 'Inappropriate title',
        'status': 'resolved',
        'createdAt': Timestamp.fromDate(now),
        'resolvedAt': Timestamp.fromDate(now),
        'resolvedBy': 'admin_uid_1',
        'resolutionNotes': 'Content hidden and author warned.',
      };

      final item = ReportItem.fromMap(map, 'spot_2_s1_r1');
      expect(item.id, 'spot_2_s1_r1');
      expect(item.status, 'resolved');
      expect(item.resolvedBy, 'admin_uid_1');
      expect(item.resolutionNotes, 'Content hidden and author warned.');
    });
  });
}
