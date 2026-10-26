class WeatherAlert {
  final String id;
  final String event;
  final String severity; // Extreme, Severe, Moderate, Minor, Unknown
  final String urgency;
  final String certainty;
  final String headline;
  final String description;
  final String instruction;
  final DateTime? effective;
  final DateTime? expires;
  final String areaDesc;
  final String senderName;

  const WeatherAlert({
    required this.id,
    required this.event,
    required this.severity,
    required this.urgency,
    required this.certainty,
    required this.headline,
    required this.description,
    required this.instruction,
    this.effective,
    this.expires,
    required this.areaDesc,
    required this.senderName,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? {};

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return WeatherAlert(
      id: json['id'] as String? ?? properties['id'] as String? ?? '',
      event: properties['event'] as String? ?? 'Weather Alert',
      severity: properties['severity'] as String? ?? 'Unknown',
      urgency: properties['urgency'] as String? ?? '',
      certainty: properties['certainty'] as String? ?? '',
      headline: properties['headline'] as String? ?? '',
      description: properties['description'] as String? ?? '',
      instruction: properties['instruction'] as String? ?? '',
      effective: parseDate(properties['effective']),
      expires: parseDate(properties['expires']),
      areaDesc: properties['areaDesc'] as String? ?? '',
      senderName: properties['senderName'] as String? ?? 'NWS',
    );
  }

  bool get isMarineRelated {
    final lowerEvent = event.toLowerCase();
    const marineKeywords = [
      'small craft',
      'gale',
      'storm warning',
      'special marine',
      'rip current',
      'tropical storm',
      'hurricane',
      'thunderstorm',
      'flood',
      'marine',
      'surf',
    ];
    return marineKeywords.any((kw) => lowerEvent.contains(kw));
  }

  int get severityWeight {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return 4;
      case 'severe':
        return 3;
      case 'moderate':
        return 2;
      case 'minor':
        return 1;
      default:
        return 0;
    }
  }

  static List<WeatherAlert> sortAlerts(List<WeatherAlert> alerts) {
    final sorted = List<WeatherAlert>.from(alerts);
    sorted.sort((a, b) {
      // Primary sort: severity weight descending
      final severityComp = b.severityWeight.compareTo(a.severityWeight);
      if (severityComp != 0) return severityComp;

      // Secondary sort: marine-related pinned to top within same severity level
      if (a.isMarineRelated && !b.isMarineRelated) return -1;
      if (!a.isMarineRelated && b.isMarineRelated) return 1;

      // Tertiary sort: event title
      return a.event.compareTo(b.event);
    });
    return sorted;
  }
}
