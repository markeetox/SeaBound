import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

class FanItemData {
  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final double dx;
  final double dy;
  final bool hasBadge;

  const FanItemData({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.dx,
    required this.dy,
    this.hasBadge = false,
  });
}

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool hasAlerts;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    this.hasAlerts = false,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  Timer? _longPressTimer;
  bool _isPointerDown = false;
  bool _isFanOpen = false;

  Offset? _pointerDownGlobalPos;
  Offset? _homeCenterGlobalPos;
  int? _highlightedIndex;

  // Key to locate Home button in global coordinate space
  final GlobalKey _homeButtonKey = GlobalKey();

  static const double _selectionRadius = 52.0;

  // 4 destinations distributed along a upper semicircular arch (R = 125dp)
  List<FanItemData> get _fanItems => [
        FanItemData(
          index: 1,
          label: 'Spots',
          icon: Icons.place_outlined,
          selectedIcon: Icons.place,
          dx: -113.3,
          dy: -52.8,
        ),
        FanItemData(
          index: 0,
          label: 'Trips',
          icon: Icons.directions_boat_outlined,
          selectedIcon: Icons.directions_boat,
          dx: -52.8,
          dy: -113.3,
        ),
        FanItemData(
          index: 3,
          label: 'Alerts',
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          dx: 52.8,
          dy: -113.3,
          hasBadge: widget.hasAlerts,
        ),
        FanItemData(
          index: 4,
          label: 'Profile',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          dx: 113.3,
          dy: -52.8,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _isPointerDown = true;
    _pointerDownGlobalPos = event.position;
    _highlightedIndex = null;

    // Calculate Home button center in global coordinates
    final renderBox =
        _homeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      _homeCenterGlobalPos =
          renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    } else {
      _homeCenterGlobalPos = event.position;
    }

    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 250), () {
      if (_isPointerDown && mounted) {
        _openFan();
      }
    });
  }

  void _openFan() {
    setState(() {
      _isFanOpen = true;
    });
    HapticFeedback.mediumImpact();
    _animController.forward();
  }

  void _closeFan() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isFanOpen = false;
          _highlightedIndex = null;
        });
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPointerDown) return;

    if (!_isFanOpen) {
      if (_pointerDownGlobalPos != null) {
        final dist = (event.position - _pointerDownGlobalPos!).distance;
        if (dist > 12.0) {
          _longPressTimer?.cancel();
        }
      }
      return;
    }

    // Fan is open - track nearest destination
    final center = _homeCenterGlobalPos ?? event.position;
    final localPointer = event.position - center;

    int? nearestIndex;
    double minDistance = double.infinity;

    for (final item in _fanItems) {
      final itemOffset = Offset(item.dx, item.dy);
      final dist = (localPointer - itemOffset).distance;
      if (dist < minDistance && dist <= _selectionRadius) {
        minDistance = dist;
        nearestIndex = item.index;
      }
    }

    if (_highlightedIndex != nearestIndex) {
      if (nearestIndex != null) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _highlightedIndex = nearestIndex;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
    final wasFanOpen = _isFanOpen;
    final selectedIdx = _highlightedIndex;

    _isPointerDown = false;

    if (wasFanOpen) {
      _closeFan();
      if (selectedIdx != null) {
        widget.onSelect(selectedIdx);
      }
    } else {
      // Normal short tap -> Navigate to Home (index 2)
      widget.onSelect(2);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();
    _isPointerDown = false;
    if (_isFanOpen) {
      _closeFan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    return SafeArea(
      bottom: true,
      top: false,
      child: SizedBox(
        height: 98,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Circular backdrop glow when fan menu is open (shifted down by 40% of its size)
            if (_isFanOpen)
              Positioned(
                bottom: 10,
                child: AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final size = (88.0 + (_expandAnimation.value * 280.0)) * 0.80;
                    return Transform.translate(
                      offset: Offset(0, size * 0.40),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35 * _expandAnimation.value),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Radial Fan Menu Items along Semicircular Arch
            if (_isFanOpen)
              ..._fanItems.map((item) {
                final isSelected = _highlightedIndex == item.index;
                final isCurrentTab = widget.currentIndex == item.index;

                return AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final progress = _expandAnimation.value;
                    final curDx = item.dx * progress;
                    final curDy = item.dy * progress;
                    final scale = progress * (isSelected ? 1.18 : 1.0);

                    return Transform.translate(
                      offset: Offset(curDx, curDy - 26.0),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: progress.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: OverflowBox(
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChromeBorderContainer(
                          borderRadius: BorderRadius.circular(8),
                          borderWidth: 1.5,
                          backgroundColor: const Color(0xFF0B2250).withValues(alpha: 0.9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? tokens.cyan : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: ChromeBorder.gradient,
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? tokens.cyan.withValues(alpha: 0.6)
                                    : Colors.black45,
                                blurRadius: isSelected ? 12 : 6,
                                spreadRadius: isSelected ? 2 : 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? tokens.cyan
                                    : isCurrentTab
                                        ? tokens.cyan.withValues(alpha: 0.85)
                                        : const Color(0xFF0B2250),
                              ),
                              child: Center(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      isSelected || isCurrentTab
                                          ? item.selectedIcon
                                          : item.icon,
                                      size: 24,
                                      color: isSelected
                                          ? tokens.onCyan
                                          : isCurrentTab
                                              ? tokens.onCyan
                                              : Colors.white,
                                    ),
                                    if (item.hasBadge)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            // Centered Home / Menu Button (compass PNG asset)
            Positioned(
              bottom: 26,
              child: Listener(
                key: _homeButtonKey,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.asset(
                    'assets/ui/home.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
