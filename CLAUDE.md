# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**渴了么 (KeLeME)** — an AI-powered hydration reminder app built with Flutter. The Flutter app lives in `ke_le_me/`. All development work happens inside that directory.

## Commands

Run all commands from `ke_le_me/`:

```bash
flutter pub get          # Install dependencies
flutter run              # Run app (add -d <device> to target a platform)
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Static analysis (run before committing)
flutter format .         # Format all Dart files
flutter build apk        # Android APK
flutter build ios        # iOS
flutter build macos      # macOS
flutter build web        # Web
```

## Architecture

### State Management
`UserProvider` (`lib/providers/user_provider.dart`) is a `ChangeNotifier` subclass that holds all runtime state — the user profile, today's water intake (`_todayMl`), and drink logs. Screens call `addListener` on it manually (no Provider package). Persistence uses `SharedPreferences`.

Data flow: `UserProvider` → `notifyListeners()` → screens call `setState()` → UI rebuilds.

### Routing
Named routes defined in `main.dart`. Initial route is `/onboarding` or `/home` based on `UserProfile.onboardingCompleted`. No deep linking or go_router.

### Models
- `UserProfile` (`lib/models/user_profile.dart`): serialized to/from `SharedPreferences` via `toMap()`/`fromMap()`. Key fields: `dailyGoalMl`, `wakeTime`, `bedTime`, `reminderIntervalMin`, `onboardingCompleted`.
- `DrinkLog` (defined inside `user_provider.dart`): `{time, icon, description, ml}`.

### Theme
All colors and text styles are in `lib/theme/app_theme.dart`. Primary palette: `bgMain` (`#F5F8FF`), `blue` (`#29B6F6`). Fonts: `Noto Sans SC` for Chinese text, `Space Mono` for numeric data.

### Custom Widgets
- `ProgressRing` (`lib/widgets/progress_ring.dart`): `CustomPaint`-based animated ring, driven by an `AnimationController` in `HomeScreen`.
- `GlassCard` (`lib/widgets/glass_card.dart`): white card with 16px radius and subtle shadow, used as a layout container throughout screens.

## Code Style (from `.cursor/rules/dart-style.mdc`)

- Files: `snake_case.dart`; classes: `UpperCamelCase`; variables/functions: `lowerCamelCase`; private members: `_prefixed`
- Import order: `dart:` → `package:flutter/` → third-party packages → local imports
- Use `const` constructors wherever possible
- Keep `build()` methods short; extract sub-widgets into named methods or classes

## Current Dependencies

The app currently uses **no Firebase or AI packages** — it is a local-first MVP. The planned AI integration (Firebase AI / Gemini) is not yet implemented.

Active dependencies: `shared_preferences`, `google_fonts`, `cupertino_icons`.

## Adding AI Features (Future)

When adding Firebase AI integration:
- Use `FirebaseAI.googleAI()` for prototyping, `FirebaseAI.vertexAI()` for production
- Models: `gemini-2.5-flash`, `gemini-2.0-flash`
- macOS requires network entitlements (`com.apple.security.network.client`) in `*.entitlements`
- Android requires `INTERNET` permission in `AndroidManifest.xml`
