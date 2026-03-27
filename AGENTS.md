# AGENTS.md

Guidelines for AI coding agents working in this repository.

## Project Overview

**KeLeME (渴了么)** — AI-powered hydration reminder app built with Flutter/Dart.
Flutter app code lives in `flutter/` (Dart package name `ke_le_me`). Run every Flutter command from that directory.

## Build / Lint / Test Commands

```bash
# All Flutter commands must be run from flutter/

flutter pub get                          # Install dependencies
flutter analyze                          # Static analysis — run before committing
flutter test                             # Run all tests
flutter test test/widget_test.dart       # Run a single test file
flutter test test/core/providers/user_provider_test.dart  # Example: run one unit test
flutter format .                         # Format all Dart files (uses dart format)
flutter run -d macos                     # Run on macOS (recommended for dev)
flutter run -d chrome                    # Run on web
flutter build apk --split-per-abi        # Production Android APK
flutter build web                        # Production web build
flutter clean && flutter pub get         # Reset build cache if issues arise
```

CI runs `flutter analyze` then `flutter test` before building (see `.github/workflows/build.yml`).
Both must pass. The APK build injects `DEEPSEEK_API_KEY` via `--dart-define`.

For Hive model changes, regenerate adapters:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Code Style

### Naming Conventions

| Entity               | Convention        | Example                          |
|----------------------|-------------------|----------------------------------|
| Files                | `snake_case.dart` | `user_provider.dart`             |
| Classes / Enums      | `UpperCamelCase`  | `UserProfile`, `DrinkLog`        |
| Variables / Functions| `lowerCamelCase`  | `todayMl`, `loadProfile()`       |
| Constants            | `lowerCamelCase`  | `defaultTimeout`                 |
| Private members      | `_prefixed`       | `_todayMl`, `_archiveDayData()`  |

### Import Order

Maintain this exact order, separated by blank lines:

```dart
import 'dart:async';               // 1. Dart SDK

import 'package:flutter/material.dart';  // 2. Flutter SDK

import 'package:shared_preferences/shared_preferences.dart';  // 3. Third-party

import '../models/user_profile.dart';    // 4. Local (relative)
```

### Formatting

- Use `flutter format .` (wraps at 80 columns by default).
- Lint rules come from `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`).
- No `.editorconfig` exists; rely on Dart formatter defaults.

### Types and Null Safety

- Prefer `final` over `var` for values that don't change.
- Use `const` constructors aggressively — widgets, padding, text styles, `SizedBox`.
- Use named parameters for functions with more than 2 parameters.
- Use `required` keyword for mandatory named parameters.
- Models serialize via `toMap()` / `fromMap()` — see `UserProfile` for the pattern.
- Hive models use generated adapters (`*.g.dart` files); annotate with `@HiveType` / `@HiveField`.

### Widget Patterns

- Prefer `StatelessWidget` class over helper methods when the subtree is stable and self-contained (enables `const`, better widget identity).
- Use `_buildXxx()` helper methods only when the subtree reads parent `State` directly.
- Keep `build()` methods short. Move expensive computation to `initState()` or provider.
- Use `RepaintBoundary` around custom paint widgets.
- Use `ValueKey` / `ObjectKey` when widgets reorder in lists.

### Error Handling

- Wrap async operations in `try-catch`. Log with `debugPrint('Error: $e')`.
- **`mounted` check is mandatory after every `await`** — including `showDialog`, `showTimePicker`, `showModalBottomSheet`, permission requests, `Future.delayed`, and network calls.

```dart
Future<void> _loadData() async {
  try {
    final result = await service.fetch();
    if (!mounted) return;
    setState(() => _data = result);
  } catch (e) {
    debugPrint('Error: $e');
  }
}
```

- No `Either`/`dartz` — use simple try-catch.

### Dispose Protocol

Dispose resources in this order inside `State.dispose()`:
1. `removeListener` on any `ChangeNotifier`
2. `AnimationController.dispose()`
3. `TextEditingController.dispose()`
4. `ScrollController.dispose()` / `PageController.dispose()`
5. `StreamSubscription.cancel()`
6. `super.dispose()` last

### Documentation

- Use `///` for public API docs. Keep comments concise.
- Document complex logic, not obvious code.

## Architecture

### State Management

`ChangeNotifier` with manual `addListener` — no Provider/Riverpod/BLoC packages.
`UserProvider` is the main app-wide notifier. Feature-specific providers (e.g., `ChatProvider`,
`PlanProvider`, `HeartProvider`) are created in `MainShell` and passed via constructors.

Data flow: Provider -> `notifyListeners()` -> screens call `setState()` -> UI rebuilds.

### Directory Structure

```
flutter/lib/
  main.dart / main_shell.dart     # App entry, bottom nav shell
  core/                           # Shared across features
    models/                       # UserProfile, DrinkLog, WeatherData, etc.
    providers/                    # UserProvider (app-wide state)
    services/                     # NotificationService, WeatherService, etc.
    theme/                        # AppTheme, AppColors
    utils/                        # GoalPredictor, helpers
  features/                       # Feature modules
    <feature>/
      models/    providers/    screens/    services/    widgets/
  common/widgets/                 # Cross-feature widgets (GlassCard, ProgressRing)
```

Do NOT introduce `data/domain/presentation` layers or `usecases/repositories` abstractions.

### Routing

Named routes in `MaterialApp.routes`. No deep linking or go_router.

### Persistence

- `SharedPreferences` for user profile and daily data.
- `Hive` for structured collections (memory facts, session summaries, custom reminders, today plans).

### Dependency Injection

Constructor injection only. Pass providers explicitly — no GetIt or service locators.

### Networking

`dio` for HTTP requests. AI backend calls go through `AiService`.
The AI API key is injected at build time via `--dart-define=DEEPSEEK_API_KEY=...`.

## Testing

- Mirror `lib/` structure in `test/` (e.g., `test/core/providers/user_provider_test.dart`).
- Use `mockito` for mocking services; mock only I/O boundaries.
- Name tests descriptively: `'addDrink increases todayMl and appends to logs'`.
- Widget tests: use `pumpWidget` and verify key interactions.

## Performance Rules

- Use `ListView.builder` / `GridView.builder` for dynamic lists — never `Column(children: list.map(...))` for unbounded data.
- Minimize `setState` scope — call it on the smallest `StatefulWidget` that needs rebuild.
- Avoid `Opacity` for hiding; use `Visibility` or conditional rendering.
- Never create new object instances inside `build()` that could be `const` or cached.
- Build release APKs with `--split-per-abi`.

## Theme

All colors and text styles live in `lib/core/theme/app_theme.dart`.
Use `AppColors.*` constants — never hardcode color hex values in widgets.
Fonts: `Noto Sans SC` for Chinese text, `Space Mono` for numeric data.

## Anti-Patterns to Avoid

- Business logic inside `build()` methods.
- Deeply nesting widgets (>5 levels) without extracting.
- Hardcoding colors/sizes instead of using `AppColors` / `AppTheme`.
- Missing `mounted` check after any `await`.
- `setState` from inside `dispose()`.
- Forgetting to `cancel()` a `StreamSubscription` in `dispose()`.
- Introducing state management packages (Provider, Riverpod, BLoC).
