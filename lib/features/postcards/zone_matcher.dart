import 'dart:math' as math;

import 'postcard_model.dart';

class ZoneMatcher {
  static const double earthRadiusMeters = 6371000.0;

  static double haversineDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static bool isInsideCircle({
    required double userLat,
    required double userLng,
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
  }) {
    final distance = haversineDistanceMeters(userLat, userLng, centerLat, centerLng);
    return distance <= radiusMeters;
  }

  static List<Postcard> matchPostcards({
    required double userLat,
    required double userLng,
    required List<Postcard> activePostcards,
  }) {
    final hits = <Postcard>[];

    for (final card in activePostcards) {
      if (!card.active) continue;
      if (isInsideCircle(
        userLat: userLat,
        userLng: userLng,
        centerLat: card.zone.lat,
        centerLng: card.zone.lng,
        radiusMeters: card.zone.radiusMeters,
      )) {
        hits.add(card);
      }
    }

    return hits;
  }

  static double _degToRad(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  static String encodeGeohash(double lat, double lng, {int precision = 6}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    double minLat = -90.0, maxLat = 90.0;
    double minLng = -180.0, maxLng = 180.0;

    final buffer = StringBuffer();
    bool isEven = true;
    int bit = 0;
    int ch = 0;

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          ch |= 1 << (4 - bit);
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= 1 << (4 - bit);
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }
}
