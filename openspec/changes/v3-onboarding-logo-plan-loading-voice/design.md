## Context

KeLeME Flutter 客户端已有完整 onboarding、今日计划（AI 流式生成）、多平台构建。`.cursor/project/todo.md` 第 1、3、4、5、6 项要求：修复引导时间显示、多端 Logo 与版本 3.0、压缩计划生成页加载态、设置内音色 UI 占位。本变更**仅 `flutter/`**，不修改 `backend/` 与 `web/`。

## Goals / Non-Goals

**Goals:**

- 引导中用户设置的起床/就寝等时间与界面展示、保存到 `UserProfile` 的路径一致，无错位、无截断或错误格式化。
- iOS、macOS（及核对 Android）应用图标与当前品牌一致；`pubspec.yaml` 与平台构建号对齐 **3.0.x**（具体 build 号按发布约定）。
- `PlanStatus.generating` 时，用户可见的「正在生成」主信息**仅一处**（推荐：卡片内主区域），避免与顶栏禁用按钮重复堆叠同义文案。
- 设置 → 基础设置中增加「音色」入口：多选项、可选中态、可持久化到 `SharedPreferences` 的 key（无 API）。

**Non-Goals:**

- 心连心等社区功能（todo 第 2 项）。
- 真实 TTS、MiniMax 或任何后端音色接口。
- 修改 AI 计划生成协议、Prompt 或 `PlanProvider` 的解析逻辑（除非为修复显示 bug 所必需的最小改动）。

## Decisions

1. **引导时间**：优先在 `onboarding_screen.dart` 中核对 `TimeOfDay` / `UserProfile.wakeTime` & `bedTime` 的字符串格式化（如 `HH:mm`）、以及时间选择回写与 `setState` 的同步。若历史 bug 与主题 `TextStyle` 溢出相关，用 `FittedBox` 或固定 `maxLines` 与 `overflow` 约束。
2. **时间选择器形态**：使用 **`showDialog` 居中** + **`CupertinoDatePicker`（`mode: time`，`use24hFormat: true`）** 实现上下滚轮，避免表盘式 `TimePickerEntryMode.dial` 与底部弹层；取消/完成在对话框顶栏。
3. **起床 / 就寝先后（同一天）**：与 `NotificationService.scheduleReminders` 的「从起床扫到当日就寝」一致，**同一自然日内须满足 起床时间早于就寝时间**；若用户选成无效组合，**自动微调**另一项并 `SnackBar` 提示（优先推后就寝或前移起床）。
4. **Loading 合并**：`plan_screen.dart` 在 `PlanStatus.generating` 时，顶栏主按钮区改为**不显示**与卡片内重复的「AI 生成中…」长条按钮，或改为无文案的轻量占位（如 `SizedBox.shrink` / 细进度条）；`StreamingTextCard` 保留**单一**标题行 + 可选一条副文案 + 轻量动效（去掉重复的 `CircularProgressIndicator` 与标签内重复「生成」文案二选一）。
5. **版本与图标**：`version: 3.0.0+N`（或团队约定 `3.0.0+1`）；iOS/macOS 使用 `flutter_launcher_icons` 若已配置则重新 `dart run flutter_launcher_icons`，否则手工替换 `AppIcon.appiconset`；与 Android `mipmap-*` 使用同一套源图。
6. **音色 UI**：在 `settings_screen.dart` 的 `_buildBasicSettings()` 增加「音色」`ListTile` 或 `Navigator.push` 至独立 `VoiceToneSheet` / 全屏页：3～4 个预设「人物风格」选项（名称+简短描述），选中态用 `Radio`/`ChoiceChip`；选中 id 写入 `SharedPreferences` key（如 `voice_tone_preset_id`），默认值 `default`。

## Risks / Trade-offs

- **[Risk] 引导问题根因多样（时区、locale、溢出）** → 修复后在 iOS/Android/macOS 各至少跑一次完整 onboarding。
- **[Risk] 去掉顶栏 loading 后用户不知在生成** → 保留卡片内明确「生成中」与流式 tips 区域，必要时保留顶部细线性进度条。
- **[Risk] 图标替换遗漏某一分辨率** → 用 `flutter_launcher_icons` 或对照 Apple 人机界面指南检查 `Contents.json` 全条目。

## Migration Plan

- 常规发版：无数据迁移；音色 key 不存在时使用默认预设。
- 回滚：Git revert；版本号与资源可单独回退。

## Open Questions

- 对外展示版本是否严格为 `3.0.0` 还是 `3.0`（商店文案）；与 `+` build 号递增策略。
- 音色预设文案是否使用占位名（如「温柔女声」）直至产品定稿。
