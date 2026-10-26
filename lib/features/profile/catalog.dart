class AchievementBadge {
  final String id;
  final String name;
  final String description; // How it's earned
  final String hint; // Shown when locked
  final int xp;
  final String imageAsset;
  final String unlockType; // 'auto' or 'qr'
  final int sortOrder;

  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.hint,
    required this.xp,
    required this.imageAsset,
    this.unlockType = 'auto',
    required this.sortOrder,
  });
}

class Catalog {
  static final DateTime foundingCrewCutoff = DateTime(2026, 12, 31, 23, 59, 59);

  static final List<AchievementBadge> starterBadges = [
    const AchievementBadge(
      id: 'welcome_aboard',
      name: 'Welcome Aboard',
      description: 'Create your Seabound account.',
      hint: 'Create a Seabound account.',
      xp: 25,
      imageAsset: 'assets/badges/welcome.png',
      sortOrder: 1,
    ),
    const AchievementBadge(
      id: 'colors_raised',
      name: 'Colors Raised',
      description: 'Set up your username and choose an avatar.',
      hint: 'Choose a username and avatar in Profile.',
      xp: 25,
      imageAsset: 'assets/badges/color.png',
      sortOrder: 2,
    ),
    const AchievementBadge(
      id: 'first_log',
      name: 'First Log',
      description: 'Log your first fishing trip.',
      hint: 'Log 1 trip in the Trips tab.',
      xp: 50,
      imageAsset: 'assets/badges/first.png',
      sortOrder: 3,
    ),
    const AchievementBadge(
      id: 'regular',
      name: 'Regular Sailor',
      description: 'Log 5 fishing trips.',
      hint: 'Log 5 trips in the Trips tab.',
      xp: 100,
      imageAsset: 'assets/badges/regular.png',
      sortOrder: 4,
    ),
    const AchievementBadge(
      id: 'salty_dog',
      name: 'Salty Dog',
      description: 'Log 25 fishing trips.',
      hint: 'Log 25 trips in the Trips tab.',
      xp: 250,
      imageAsset: 'assets/badges/salty.png',
      sortOrder: 5,
    ),
    const AchievementBadge(
      id: 'spot_finder',
      name: 'Spot Finder',
      description: 'Share your first fishing spot on the map.',
      hint: 'Post 1 fishing spot.',
      xp: 50,
      imageAsset: 'assets/badges/master.png',
      sortOrder: 6,
    ),
    const AchievementBadge(
      id: 'chart_reader',
      name: 'Chart Reader',
      description: 'Turn on the Depth & Bathymetry map layer.',
      hint: 'Toggle the Depth layer on the map.',
      xp: 25,
      imageAsset: 'assets/badges/chart.png',
      sortOrder: 7,
    ),
    const AchievementBadge(
      id: 'weather_eye',
      name: 'Weather Eye',
      description: 'Check active weather & marine alerts.',
      hint: 'Open the Alerts tab.',
      xp: 25,
      imageAsset: 'assets/badges/weather.png',
      sortOrder: 8,
    ),
    const AchievementBadge(
      id: 'navigator',
      name: 'Navigator',
      description: 'Use the My Location button on the map.',
      hint: 'Tap the My Location button on the map.',
      xp: 25,
      imageAsset: 'assets/badges/pirate.png',
      sortOrder: 9,
    ),
    AchievementBadge(
      id: 'founding_crew',
      name: 'Founding Crew',
      description: 'Join Seabound as an early member.',
      hint: 'Create an account before Dec 31, 2026.',
      xp: 100,
      imageAsset: 'assets/badges/founding.png',
      sortOrder: 10,
    ),
    const AchievementBadge(
      id: 'friend_markeetox',
      name: 'Markeetox',
      description: 'Add markeetox as a friend.',
      hint: 'Friend user markeetox.',
      xp: 500,
      imageAsset: 'assets/badges/markeetox.png',
      sortOrder: 11,
    ),
    const AchievementBadge(
      id: 'friend_osnola26',
      name: 'Osnola26',
      description: 'Add osnola26 as a friend.',
      hint: 'Friend user osnola26.',
      xp: 500,
      imageAsset: 'assets/badges/osnola.png',
      sortOrder: 12,
    ),
  ];

  static AchievementBadge? getBadgeById(String id) {
    try {
      return starterBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  // Level curve: total XP needed to reach level L = 50 * L * (L - 1)
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return 50 * level * (level - 1);
  }

  static int getLevelFromXp(int totalXp) {
    int level = 1;
    while (totalXp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  // Titles list
  static const List<Map<String, dynamic>> titles = [
    {'minLevel': 18, 'title': 'Sea Legend'},
    {'minLevel': 12, 'title': 'Pirate'},
    {'minLevel': 8, 'title': 'Captain'},
    {'minLevel': 5, 'title': 'First Mate'},
    {'minLevel': 3, 'title': 'Angler'},
    {'minLevel': 1, 'title': 'Deckhand'},
  ];

  static String getTitleFromLevel(int level) {
    for (final t in titles) {
      if (level >= (t['minLevel'] as int)) {
        return t['title'] as String;
      }
    }
    return 'Deckhand';
  }

  // Offensive words blocklist
  static const Set<String> offensiveBlocklist = {
    'admin',
    'root',
    'support',
    'official',
    'moderator',
    'seabound',
    'fuck',
    'shit',
    'bitch',
    'asshole',
  };

  static String? validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return 'Please enter a username.';
    }
    final trimmed = username.trim();
    if (trimmed.length < 3 || trimmed.length > 20) {
      return 'Username must be between 3 and 20 characters.';
    }
    final validRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validRegex.hasMatch(trimmed)) {
      return 'Only letters, numbers, and underscores are allowed.';
    }
    if (offensiveBlocklist.contains(trimmed.toLowerCase())) {
      return 'This username is reserved or not allowed.';
    }
    return null;
  }
}
