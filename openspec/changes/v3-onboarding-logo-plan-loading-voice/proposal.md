## Why

`.cursor/project/todo.md` 中多项体验与发布项需一次性落地：引导里作息时间展示仍不稳定（曾修复仍复发）；仅 Android APK 已换新 Logo，iOS/macOS 等需对齐；版本需升至 **3.0**；AI 生成今日计划时顶栏、卡片内标签、动效与底部文案重复表达「加载中」，信息噪音大；设置中需预留「音色」类选项的展示与交互原型（不接后端）。以上均为 **Flutter 客户端**范围，不涉及 `web/`，本变更也不扩展后端 API。

## What Changes

- **引导 / 时间**：排查并修复 onboarding 流程中与起床、就寝等时间相关的**显示与绑定**问题；完成后需人工在真机或模拟器完整走一遍引导确认。
- **品牌资源**：在 `flutter/` 各平台（至少 **iOS、macOS**；与 Android 现有一致）更新应用图标 / 启动图等启动器资源，使与当前品牌一致。
- **版本号**：将应用对外版本统一为 **3.0**（`pubspec.yaml` 及 iOS `Info.plist`、macOS 工程、Android 等需与团队约定一致）。
- **计划生成 Loading**：在「今日计划」生成过程中，将多处并行的加载提示合并为**单一、清晰**的加载反馈（例如保留一处主文案 + 必要动效，避免顶栏按钮文案与卡片内标签/底部说明重复堆叠）。
- **设置 / 音色（仅 UI）**：在「设置 → 基础设置」增加音色相关入口：以按钮或选项形式展示多种人物风格（文案可对标豆包等产品的音色选择体验）；**不调用** MiniMax 等真实 API，不实现后端。

## Capabilities

### New Capabilities

- `onboarding-time-display`: 引导流程中作息时间展示与选择的一致性、验收口径（人工复测）。
- `app-launcher-icons-multiplatform`: 多平台应用图标与品牌资源对齐（相对当前仅 APK 已更新的缺口）。
- `app-version-semver-3`: 应用版本号升级为 3.0 及各平台元数据一致。
- `ai-plan-generation-loading-ui`: AI 生成饮水计划过程中的加载态 UI 去重与信息架构。
- `settings-voice-tone-ui`: 设置内音色选项的展示与本地交互原型（无网络、无后端）。

### Modified Capabilities

- `daily-plan`（`openspec/specs/daily-plan.md`）：在 REQ-PLAN-02 相关行为不变前提下，补充「生成中」界面层需求以引用 `ai-plan-generation-loading-ui` 规格中的场景，或在本变更的 capability 规格中独立完整描述加载 UI（实现时以本变更 `specs/` 为准，必要时再合并回主规格）。

## Impact

- **Flutter**：`flutter/lib/features/onboarding/`（或引导相关屏幕）；`flutter/macos/`、`flutter/ios/`、`flutter/android/` 资源与配置；`flutter/pubspec.yaml`；`flutter/lib/features/plan/`（`plan_screen.dart`、`streaming_text_card.dart` 等）；`flutter/lib/features/settings/` 下基础设置相关屏幕。
- **Backend**：无。
- **依赖**：不新增为完成本变更所必需的生产依赖；音色若仅本地状态可用 `SharedPreferences` 或内存，无需新包。
