# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**渴了么 (KeLeME)** — an AI-powered hydration reminder app built with Flutter. This repo is a **monorepo**: Flutter client in `flutter/`, Next.js site in `web/`, API in `backend/`. Flutter commands below are run from `flutter/`.

## Commands

Run all commands from `flutter/`:

```bash
flutter pub get          # Install dependencies
flutter run              # Run app (add -d <device> to target a platform)
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Static analysis (run before committing)
flutter format .         # Format all Dart files
flutter build apk        # Android APK
flutter build ios        # iOS (requires Xcode)
flutter build macos      # macOS (requires Xcode)
flutter build web        # Web
flutter clean            # Clear build cache (use before pub get if issues)
```

## Requirements

- **Dart SDK**: ^3.11.1 (declared in `pubspec.yaml`)
- **Platform-specific**:
  - **macOS**: Xcode with macOS desktop support enabled (`flutter config --enable-macos-desktop`)
  - **iOS**: Xcode with iOS development tools
  - **Android**: Android Studio with Android SDK
  - **Web**: Chrome browser

## Architecture

### State Management

`UserProvider` (`lib/providers/user_provider.dart`) is a `ChangeNotifier` subclass that holds all runtime state — the user profile, today's water intake (`_todayMl`), and drink logs. Screens call `addListener` on it manually (no Provider package). Persistence uses `SharedPreferences`.

Data flow: `UserProvider` → `notifyListeners()` → screens call `setState()` → UI rebuilds.

### Routing

Named routes defined in `main.dart`. Initial route is `/onboarding` or `/home` based on `UserProfile.onboardingCompleted`. No deep linking or go_router.

### Models

- `UserProfile` (`lib/models/user_profile.dart`): serialized to/from `SharedPreferences` via `toMap()`/`fromMap()`. Key fields: `dailyGoalMl`, `wakeTime`, `bedTime`, `reminderIntervalMin`, `reminderStyle`, `notificationsEnabled`, `onboardingCompleted`.
- `DrinkLog` (defined inside `user_provider.dart`): `{time, icon, description, ml}`.

### Data Persistence

`SharedPreferences` keys used by `UserProvider`:

- `user_profile`: Serialized `UserProfile`
- `today_date`: Current date string (for day rollover detection)
- `today_ml`: Today's total water intake
- `today_logs`: Today's drink logs (JSON array)
- `monthly_hits_{year}_{month}`: Map of day → totalMl for calendar display
- `history_{date}`: Daily totals for streak calculation (kept for 365 days)

Day rollover: On app launch or `addDrink()`, checks if date changed. If so, archives previous day's data to `history_{date}` and `monthly_hits`, then resets counters. Streak calculation walks backward from today counting consecutive days where goal was met.

### Theme

All colors and text styles are in `lib/theme/app_theme.dart`. Primary palette: `bgMain` (`#F5F8FF`), `blue` (`#29B6F6`). Fonts: `Noto Sans SC` for Chinese text, `Space Mono` for numeric data.

### Custom Widgets

- `ProgressRing` (`lib/widgets/progress_ring.dart`): `CustomPaint`-based animated ring, driven by an `AnimationController` in `HomeScreen`.
- `GlassCard` (`lib/widgets/glass_card.dart`): white card with 16px radius and subtle shadow, used as a layout container throughout screens.

### Notification System

`NotificationService` (`lib/services/notification_service.dart`) is a singleton that handles scheduled water reminders using `flutter_local_notifications`.

- Uses `timezone` package for proper scheduling across time zones
- Schedules notifications for 7 days ahead, rescheduled on app launch
- Three reminder styles: 温柔 (gentle), 活泼 (lively), 严肃 (serious)
- Platform permissions requested explicitly on Android, iOS, macOS

Notification flow: `UserProvider.saveProfile()` → `NotificationService.scheduleReminders()` → notifications scheduled between wake time and bed time at configured intervals.

## Code Style (from `.cursor/rules/dart-style.mdc`)

- Files: `snake_case.dart`; classes: `UpperCamelCase`; variables/functions: `lowerCamelCase`; private members: `_prefixed`
- Import order: `dart:` → `package:flutter/` → third-party packages → local imports
- Use `const` constructors wherever possible
- Keep `build()` methods short; extract sub-widgets into named methods or classes

## Current Dependencies

Active dependencies: `shared_preferences`, `google_fonts`, `cupertino_icons`, `flutter_local_notifications`, `timezone`, `flutter_timezone`.

The app is local-first — all data persists via `SharedPreferences`. No backend integration yet.

## Adding AI Features (Future)

**Note**: AI integration is planned but not yet implemented. The app currently runs fully offline with local data only.

When adding AI integration:

- Use a custom backend to proxy requests to the AI model (e.g. `gemini-2.5-flash`)
- macOS requires network entitlements (`com.apple.security.network.client`) in `*.entitlements`
- Android requires `INTERNET` permission in `AndroidManifest.xml`

## Platform-Specific Notes

### Notifications

- **macOS**: Requires `com.apple.security.network.client` entitlement in `DebugProfile.entitlements` and `Release.entitlements` for timezone data download
- **Android**: `POST_NOTIFICATIONS` permission (Android 13+) handled by `flutter_local_notifications`
- **iOS/macOS**: Notification permissions requested at runtime via `NotificationService.requestPermission()`

### Running on Different Platforms

```bash
flutter run -d macos    # Recommended for development
flutter run -d chrome   # Web version (notifications may be limited)
flutter run -d <device_id>  # iOS/Android with device from `flutter devices`
```

## Troubleshooting

### No devices found

Run `flutter doctor` to check environment setup, then `flutter devices` to list available targets. Common issues:

- Android: Start emulator via Android Studio Device Manager
- iOS: Open Simulator with `open -a Simulator`
- macOS: Enable desktop support with `flutter config --enable-macos-desktop`

### Build or dependency issues

```bash
flutter clean
flutter pub get
flutter run -d macos
```

### macOS font loading errors

If Google Fonts fail to load, the app may lack network permissions. Add `com.apple.security.network.client` to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.

### Detailed logging

Use `flutter run -v` for verbose output when debugging build or runtime issues.

## 环境

- 所有容器相关任务（包括 PostgreSQL 和数据库设置）使用 Podman（而非 Docker 或 Homebrew）

添加到 ## 工作流部分

## 工作流

- 遵循 `.cursor/project/README.md` 中的约定或多步骤计划时，按顺序进行，除非有错误或歧义，否则不在步骤之间请求确认
- **后端 VPS 部署规范**（默认 PM2 + 仅容器跑 DB）：`.cursor/project/后端部署规范.md`

## 项目结构

- Flutter 前端和后端是分开的；调试集成问题时，检查 UserProvider 同步到后端作为常见故障点

## OpenSpec（规范驱动开发）

本仓库已在**根目录**初始化 [OpenSpec](https://github.com/Fission-AI/OpenSpec)（`openspec/config.yaml`）。用于在写代码前对齐 **proposal / spec delta / design / tasks**，并与 Cursor、Claude Code 的 slash 命令集成。

### 范围（重要）

- **默认纳入 OpenSpec 产物**：**Flutter 客户端**（`flutter/`）与 **后端**（`backend/`）。
- **默认不纳入**：**Next.js 站点**（`web/`）。编写或评审规格、任务清单时**不要**把 `web/` 当作受影响路径，除非用户**明确**要求做官网相关或跨 `web/` 的变更。

范围与规则写在 `openspec/config.yaml` 的 `context` 与 `rules` 中；生成或修改 OpenSpec 文档时应遵守。

### CLI

- 需要 **Node.js ≥ 20.19**（与 Flutter 无关，仅用于 OpenSpec CLI）。
- 安装：`npm install -g @fission-ai/openspec@latest`（或使用 `npx @fission-ai/openspec@latest <command>`）。
- 常用：`openspec list`、`openspec validate`、`openspec show`；变更工作流见官方文档。

### 编辑器工作流（初始化时已写入）

- Cursor：`.cursor/commands/` 下的 `/opsx:propose`、`/opsx:apply`、`/opsx:archive` 等；技能见 `.cursor/skills/openspec-*`。
- Claude Code：`.claude/commands/opsx/` 与 `.claude/skills/openspec-*`。

首次使用可执行 `/opsx:propose "描述你的需求"`，按提示在 `openspec/changes/<name>/` 下产出工件；实现完成后 `/opsx:archive` 归档并合并主规格。重启 IDE 后 slash 命令生效。
