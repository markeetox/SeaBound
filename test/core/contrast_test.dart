import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/app_theme.dart';

double _calculateLuminance(Color color) {
  double transform(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    } else {
      return pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  final r = transform(color.r);
  final g = transform(color.g);
  final b = transform(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _calculateContrastRatio(Color color1, Color color2) {
  final l1 = _calculateLuminance(color1);
  final l2 = _calculateLuminance(color2);

  final lighter = max(l1, l2);
  final darker = min(l1, l2);

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG 2.1 Color Contrast Ratio Unit Tests', () {
    final tokens = OceanThemeExtension.defaultTokens;

    final lighterBlueBg = tokens.blueBottom;
    final lighterRedBg = tokens.redTop;

    test('Primary text against lighter Blue background has >= 7:1 contrast', () {
      final ratio = _calculateContrastRatio(tokens.text, lighterBlueBg);
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('Secondary text against lighter Blue background has >= 4.5:1 contrast', () {
      final ratio = _calculateContrastRatio(tokens.textSecondary, lighterBlueBg);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Primary text against lighter Red background has >= 7:1 contrast', () {
      final ratio = _calculateContrastRatio(tokens.text, lighterRedBg);
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('Secondary text against lighter Red background has >= 4.5:1 contrast', () {
      final ratio = _calculateContrastRatio(tokens.textSecondary, lighterRedBg);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('White text against Red FAB (#D1142A) background has >= 4.5:1 contrast', () {
      const redFabColor = Color(0xFFD1142A);
      const whiteText = Colors.white;
      final ratio = _calculateContrastRatio(whiteText, redFabColor);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });
}
