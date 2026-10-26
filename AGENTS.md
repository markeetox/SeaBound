# AGENTS.md

## General Instructions & Guidelines for Agents

- **Secrets & API Keys**: Never commit secrets, credentials, or API keys to the repository. Ensure sensitive items are kept in ignored configuration files or environment variables.
- **Cross-Platform Support**: The app must support iOS, Android, and Flutter web.
- **Package Selection**: Avoid adding packages or dependencies that do not support web or mobile platforms.
- **Responsive Layouts**: Layouts must be responsive and function seamlessly on phone-sized screens as well as web browsers.
- **Pre-PR Verification**: Always run `flutter analyze` and `flutter test` before submitting code changes or opening a pull request. Fix all static analysis errors, warnings, and failing tests.
- **Location Sensitivity**: Location data is sensitive: never log or upload it without explicit user action. In AsyncValue.when, the error callback takes two parameters (error, stackTrace). The class is CrossAxisAlignment.
- **Riverpod 3 Usage**: Riverpod 3 is used. Never use StateNotifier, StateNotifierProvider, or StateProvider. Use Notifier / AsyncNotifier with NotifierProvider / AsyncNotifierProvider.
- **Profile & Gamification Guidelines**:
  - Never store user email addresses in Firestore `users/{uid}` documents.
  - Usernames must be validated using `Catalog.validateUsername()` (3-20 chars, alphanumeric + underscores, blocklist check) and claimed via Firestore transaction in `/usernames/{username}`.
  - Badges are awarded atomically using `BadgeService.awardBadge()` in `users/{uid}/badges/{badgeId}`.
- **UI Rules**:
  - UI rules: no AppBar anywhere; use FloatingTopBar. Titles are w800-w900. Tap targets are at least 56 dp. Text contrast is at least 7:1. Blue gradient everywhere except the Profile screens, which are red.
  - Bottom nav: 5 circular items (Trips, Spots, Home, Alerts, Profile), Home centered and larger (76dp vs 64dp), strip background height is half the circle height (32dp strip).
  - Spots screen has no top bar or title in map view. Map fills the whole screen with control buttons in 1 row under status bar, followed by a full-width "Community Spots" button.
  - The Add pin button is a red extended FAB (`#D1142A`, white bold text, 3px white border) at the bottom right.
