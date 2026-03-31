## 1. Flutter — 引导时间显示（`onboarding-time-display`）

- [x] 1.1 在 `flutter/lib/features/onboarding/screens/onboarding_screen.dart` 复现并定位起床/就寝时间展示或保存不一致的原因（格式化、`TimeOfDay` 回写、`UserProfile` 字段）。
- [x] 1.2 实现修复（含布局溢出时使用 `FittedBox`/`maxLines` 等必要约束），并自查完成引导后 `UserProfile` 与 UI 一致。
- [ ] 1.3 **人工验收**：在至少一种目标平台（建议 iOS 或 Android + macOS）完整走一遍 onboarding，记录通过/问题。

## 2. Flutter — 版本号 3.0（`app-version-semver-3`）

- [x] 2.1 将 `flutter/pubspec.yaml` 的 `version` 更新为 `3.0.0+<build>`（或与发布流程一致的 3.0 系列与 build 号）。
- [x] 2.2 核对 iOS `Info.plist`、macOS 工程、Android `build.gradle.kts`（若未由 Flutter 全量同步）中对外版本与 `pubspec` 一致。

## 3. Flutter — 多平台 Logo（`app-launcher-icons-multiplatform`）

- [x] 3.1 确认与当前 APK 一致的源图标（或 `assets` 中主图标）；若使用 `flutter_launcher_icons`，更新配置并执行生成。
- [x] 3.2 更新 `ios` / `macos` 的 `AppIcon` 资源集（及 Android 若需与源图对齐）；构建并在桌面/模拟器查看主屏幕图标。

## 4. Flutter — 计划生成 Loading 去重（`ai-plan-generation-loading-ui`）

- [x] 4.1 调整 `flutter/lib/features/plan/screens/plan_screen.dart`：在 `PlanStatus.generating` 时避免顶栏「AI 生成中…」按钮与卡片内主文案重复（按 `design.md`）。
- [x] 4.2 精简 `flutter/lib/features/plan/widgets/streaming_text_card.dart`：单一主加载标题/动效，去掉冗余 `CircularProgressIndicator` 或与顶栏重复的文案层。
- [ ] 4.3 手测：生成计划过程中仅保留一处「生成中」主语义，小贴士区域可保留。

## 5. Flutter — 设置音色 UI（`settings-voice-tone-ui`）

- [x] 5.1 在 `flutter/lib/features/settings/screens/settings_screen.dart` 的 `_buildBasicSettings()` 增加「音色」入口。
- [x] 5.2 新增子页面或 bottom sheet（如 `voice_tone_sheet.dart`）：3～4 个预设选项、选中态；使用 `SharedPreferences` 持久化选中 id（无 HTTP）。
- [x] 5.3 确认切换音色不产生网络请求；`flutter analyze` 通过。

## 6. 收尾

- [x] 6.1 在 `flutter/` 运行 `flutter analyze` 与相关 `flutter test`（若有计划/onboarding 测试则一并跑）。
- [x] 6.2 运行 `openspec validate`；准备合并或 `/opsx:apply` 实现阶段。
