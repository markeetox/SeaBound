import 'package:flutter/material.dart';

import 'catalog.dart';

class BadgePin extends StatelessWidget {
  final AchievementBadge badge;
  final bool isEarned;
  final double size;

  const BadgePin({
    super.key,
    required this.badge,
    required this.isEarned,
    this.size = 56.0,
  });

  IconData _getFallbackIcon(String id) {
    switch (id) {
      case 'welcome_aboard':
        return Icons.sailing;
      case 'colors_raised':
        return Icons.flag;
      case 'first_log':
        return Icons.directions_boat;
      case 'regular':
        return Icons.anchor;
      case 'salty_dog':
        return Icons.phishing;
      case 'spot_finder':
        return Icons.place;
      case 'chart_reader':
        return Icons.map;
      case 'weather_eye':
        return Icons.visibility;
      case 'navigator':
        return Icons.explore;
      case 'founding_crew':
        return Icons.stars;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget badgeImageWidget = Image.asset(
      badge.imageAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback colored circle with icon when asset PNG is not present
        return Center(
          child: Icon(
            _getFallbackIcon(badge.id),
            size: size * 0.5,
            color: isEarned ? Colors.white : Colors.grey.shade400,
          ),
        );
      },
    );

    if (!isEarned) {
      badgeImageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      0.5, 0,
        ]),
        child: badgeImageWidget,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: badgeImageWidget,
          ),
          if (!isEarned)
            Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: Icon(
                Icons.lock,
                size: size * 0.28,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
