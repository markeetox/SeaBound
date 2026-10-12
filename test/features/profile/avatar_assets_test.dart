import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('All 9 marine avatar PNG files exist in assets/avatars', () {
    for (int i = 1; i <= 9; i++) {
      final avatarId = 'avatar_${i.toString().padLeft(2, '0')}';
      final file = File('assets/avatars/$avatarId.png');
      expect(file.existsSync(), isTrue, reason: 'Missing $avatarId.png');
    }
  });
}
