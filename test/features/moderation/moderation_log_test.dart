import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/moderation/moderation_log_model.dart';

void main() {
  group('ModerationLog Model Unit Tests', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime(2026, 11, 4, 12, 0);
      final log = ModerationLog(
        id: 'log_123',
        adminId: 'admin_456',
        contentType: 'spot',
        contentId: 'spot_789',
        previousStatus: 'active',
        newStatus: 'hidden',
        reason: 'Inappropriate language',
        createdAt: now,
      );

      final map = log.toMap();
      expect(map['id'], 'log_123');
      expect(map['adminId'], 'admin_456');
      expect(map['contentType'], 'spot');
      expect(map['contentId'], 'spot_789');
      expect(map['previousStatus'], 'active');
      expect(map['newStatus'], 'hidden');
      expect(map['reason'], 'Inappropriate language');

      final fromMap = ModerationLog.fromMap(
        {
          'id': 'log_123',
          'adminId': 'admin_456',
          'contentType': 'spot',
          'contentId': 'spot_789',
          'previousStatus': 'active',
          'newStatus': 'hidden',
          'reason': 'Inappropriate language',
          'createdAt': now.toIso8601String(),
        },
        'log_123',
      );

      expect(fromMap.id, 'log_123');
      expect(fromMap.adminId, 'admin_456');
      expect(fromMap.previousStatus, 'active');
      expect(fromMap.newStatus, 'hidden');
      expect(fromMap.reason, 'Inappropriate language');
    });
  });
}
