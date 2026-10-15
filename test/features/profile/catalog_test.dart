import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/profile/catalog.dart';

void main() {
  group('Catalog Level Curve Tests', () {
    test('XP required for level math formula', () {
      expect(Catalog.xpForLevel(1), equals(0));
      expect(Catalog.xpForLevel(2), equals(100)); // 50 * 2 * 1 = 100
      expect(Catalog.xpForLevel(3), equals(300)); // 50 * 3 * 2 = 300
      expect(Catalog.xpForLevel(4), equals(600)); // 50 * 4 * 3 = 600
      expect(Catalog.xpForLevel(5), equals(1000)); // 50 * 5 * 4 = 1000
    });

    test('getLevelFromXp and getTitleFromLevel return correct values', () {
      final lvl1 = Catalog.getLevelFromXp(0);
      expect(lvl1, equals(1));
      expect(Catalog.getTitleFromLevel(lvl1), equals('Deckhand'));

      final lvl2 = Catalog.getLevelFromXp(200);
      expect(lvl2, equals(2));

      final lvl3 = Catalog.getLevelFromXp(300);
      expect(lvl3, equals(3));
      expect(Catalog.getTitleFromLevel(lvl3), equals('Angler'));

      final highLvl = Catalog.getLevelFromXp(5000);
      expect(highLvl, equals(10));
      expect(Catalog.getTitleFromLevel(highLvl), equals('Captain'));
    });
  });

  group('Catalog Username Validator Tests', () {
    test('validates correct usernames', () {
      expect(Catalog.validateUsername('captain_jack'), isNull);
      expect(Catalog.validateUsername('salty_dog88'), isNull);
      expect(Catalog.validateUsername('mariner'), isNull);
    });

    test('rejects short usernames', () {
      expect(Catalog.validateUsername('ab'), equals('Username must be between 3 and 20 characters.'));
    });

    test('rejects long usernames', () {
      expect(
        Catalog.validateUsername('a' * 21),
        equals('Username must be between 3 and 20 characters.'),
      );
    });

    test('rejects invalid characters', () {
      expect(
        Catalog.validateUsername('captain-jack'),
        equals('Only letters, numbers, and underscores are allowed.'),
      );
    });

    test('rejects reserved/blocklisted words', () {
      expect(Catalog.validateUsername('admin'), equals('This username is reserved or not allowed.'));
      expect(Catalog.validateUsername('seabound'), equals('This username is reserved or not allowed.'));
    });
  });

  group('Catalog Badges List Tests', () {
    test('contains expected starter badges including friend badges', () {
      final starterIds = Catalog.starterBadges.map((b) => b.id).toList();
      expect(starterIds, contains('welcome_aboard'));
      expect(starterIds, contains('colors_raised'));
      expect(starterIds, contains('first_log'));
      expect(starterIds, contains('spot_finder'));
      expect(starterIds, contains('founding_crew'));
      expect(starterIds, contains('friend_markeetox'));
      expect(starterIds, contains('friend_osnola26'));

      final markeetox = Catalog.getBadgeById('friend_markeetox');
      expect(markeetox, isNotNull);
      expect(markeetox!.xp, equals(500));
      expect(markeetox.imageAsset, equals('assets/badges/markeetox.png'));

      final osnola = Catalog.getBadgeById('friend_osnola26');
      expect(osnola, isNotNull);
      expect(osnola!.xp, equals(500));
      expect(osnola.imageAsset, equals('assets/badges/osnola.png'));
    });
  });
}
