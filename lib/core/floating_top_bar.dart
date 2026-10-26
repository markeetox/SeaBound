import 'package:flutter/material.dart';
import 'app_theme.dart';

class FloatingTopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isRedScreen;
  final Widget? badge;

  const FloatingTopBarButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isRedScreen = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    Widget button = Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: ChromeBorder.gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: Icon(icon, size: 28, color: tokens.text),
              onPressed: onPressed,
              tooltip: tooltip,
            ),
          ),
        ),
      ),
    );

    if (badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -2,
            right: -2,
            child: badge!,
          ),
        ],
      );
    }

    return button;
  }
}

class FloatingTopBar extends StatelessWidget {
  final Widget? leading;
  final List<Widget> actions;
  final bool isRedScreen;

  const FloatingTopBar({
    super.key,
    this.leading,
    this.actions = const [],
    this.isRedScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && canPop) {
      leadingWidget = FloatingTopBarButton(
        icon: Icons.arrow_back,
        tooltip: 'Back',
        isRedScreen: isRedScreen,
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            leadingWidget ?? const SizedBox(width: 56, height: 56),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: action,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
