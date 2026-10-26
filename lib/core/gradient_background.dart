import 'package:flutter/material.dart';
import 'app_theme.dart';

enum GradientVariant { blue, red }

class GradientBackground extends StatelessWidget {
  final Widget child;
  final GradientVariant variant;
  final Color? customColor;

  const GradientBackground({
    super.key,
    required this.child,
    this.variant = GradientVariant.blue,
    this.customColor,
  });

  const GradientBackground.blue({
    super.key,
    required this.child,
    this.customColor,
  }) : variant = GradientVariant.blue;

  const GradientBackground.red({
    super.key,
    required this.child,
    this.customColor,
  }) : variant = GradientVariant.red;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    final Color topColor;
    final Color bottomColor;

    if (customColor != null) {
      topColor = Color.alphaBlend(Colors.black.withValues(alpha: 0.30), customColor!);
      bottomColor = Color.alphaBlend(Colors.black.withValues(alpha: 0.85), customColor!);
    } else {
      topColor =
          variant == GradientVariant.blue ? tokens.blueTop : tokens.redTop;
      bottomColor =
          variant == GradientVariant.blue ? tokens.blueBottom : tokens.redBottom;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
      child: child,
    );
  }
}
