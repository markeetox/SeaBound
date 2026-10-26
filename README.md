# Seabound

Seabound is a community application for fishermen and boaters built with Flutter.

## Features

- **Auth**: Login and Sign Up screens
- **Trips**: Log and plan fishing and boating voyages
- **Spots**: Discover and share popular fishing spots and marinas
- **Alerts**: Receive weather and safety warnings
- **Profile**: Manage captain and vessel preferences

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.13+ or stable channel)
- Xcode (for iOS development/simulation)
- Android Studio / Android SDK (for Android development/simulation)
- Chrome / Edge or any modern web browser (for Web execution)

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd seabound
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:

   - **Web**:
     ```bash
     flutter run -d chrome
     ```

   - **Android**:
     ```bash
     flutter run -d android
     ```

   - **iOS**:
     ```bash
     flutter run -d ios
     ```

## Code Quality & Verification

Before submitting pull requests, run static analysis and tests:

```bash
flutter analyze
flutter test
```
