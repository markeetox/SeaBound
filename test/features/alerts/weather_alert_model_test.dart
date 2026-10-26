import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/alerts/weather_alert_model.dart';

void main() {
  group('WeatherAlert Model Tests', () {
    test('WeatherAlert.fromJson parses GeoJSON feature properties correctly', () {
      final json = {
        'id': 'NWS-ALERT-123',
        'properties': {
          'event': 'Small Craft Advisory',
          'severity': 'Moderate',
          'urgency': 'Expected',
          'certainty': 'Likely',
          'headline': 'Small Craft Advisory in effect until 8 PM EST',
          'description': 'Winds 15 to 25 knots with seas 3 to 5 feet.',
          'instruction': 'Inexperienced mariners should avoid navigating.',
          'effective': '2025-05-15T12:00:00Z',
          'expires': '2025-05-15T20:00:00Z',
          'areaDesc': 'Biscayne Bay; Coastal Waters',
          'senderName': 'NWS Miami FL',
        },
      };

      final alert = WeatherAlert.fromJson(json);

      expect(alert.id, 'NWS-ALERT-123');
      expect(alert.event, 'Small Craft Advisory');
      expect(alert.severity, 'Moderate');
      expect(alert.isMarineRelated, true);
      expect(alert.severityWeight, 2);
      expect(alert.areaDesc, 'Biscayne Bay; Coastal Waters');
      expect(alert.senderName, 'NWS Miami FL');
    });

    test('WeatherAlert.sortAlerts places higher severity first and pins marine alerts', () {
      const minorLand = WeatherAlert(
        id: '1',
        event: 'Heat Advisory',
        severity: 'Minor',
        urgency: '',
        certainty: '',
        headline: '',
        description: '',
        instruction: '',
        areaDesc: '',
        senderName: '',
      );

      const severeLand = WeatherAlert(
        id: '2',
        event: 'Severe Thunderstorm Warning',
        severity: 'Severe',
        urgency: '',
        certainty: '',
        headline: '',
        description: '',
        instruction: '',
        areaDesc: '',
        senderName: '',
      );

      const moderateMarine = WeatherAlert(
        id: '3',
        event: 'Small Craft Advisory',
        severity: 'Moderate',
        urgency: '',
        certainty: '',
        headline: '',
        description: '',
        instruction: '',
        areaDesc: '',
        senderName: '',
      );

      const moderateLand = WeatherAlert(
        id: '4',
        event: 'Wind Advisory',
        severity: 'Moderate',
        urgency: '',
        certainty: '',
        headline: '',
        description: '',
        instruction: '',
        areaDesc: '',
        senderName: '',
      );

      final sorted = WeatherAlert.sortAlerts([
        minorLand,
        moderateLand,
        moderateMarine,
        severeLand,
      ]);

      expect(sorted[0].id, '2'); // Severe (highest weight)
      expect(sorted[1].id, '3'); // Moderate Marine (pinned over Moderate Land)
      expect(sorted[2].id, '4'); // Moderate Land
      expect(sorted[3].id, '1'); // Minor Land
    });
  });
}
