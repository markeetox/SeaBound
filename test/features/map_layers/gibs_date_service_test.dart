import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/map_layers/gibs_date_service.dart';

void main() {
  group('GibsDateService Unit Tests', () {
    test('formatDisplayDate formats ISO date string correctly', () {
      expect(GibsDateService.formatDisplayDate('2025-10-05'), equals('Oct 5'));
      expect(GibsDateService.formatDisplayDate('2025-01-01'), equals('Jan 1'));
      expect(GibsDateService.formatDisplayDate('invalid-date'), equals('invalid-date'));
    });
  });
}
