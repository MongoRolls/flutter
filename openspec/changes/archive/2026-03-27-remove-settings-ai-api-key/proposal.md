## Why

个人设置中仍暴露「AI 助手配置」（自定义 DeepSeek API Key 等），与产品希望收敛配置入口、简化设置页的目标不一致；该能力不应再在「个人设置」中向普通用户展示。

## What Changes

- 从 Flutter「个人设置」页（`SettingsScreen`）移除「AI 助手配置」整块 UI（标题、说明、Key 输入、「保存 API Key」等）。
- 删除仅服务于该区块的 State、构建方法、保存逻辑及不再需要的 import；移除 `ListView` 中对应子组件调用，避免死代码。
- **不**下线应用内 AI 聊天、计划或其它依赖 `AiConfig.load()` 的能力；**不**在本变更中擅自清除本地已保存的自定义 Key（若需清除或限制其它入口，另立项）。
- **不**删除「AI 健康档案」区块或 `HealthArchiveScreen`。
- **不**要求修改后端代理或 `AiConfig.load()` 的默认策略（除非单独立项）。
- **不**默认包含 Next.js 官网（`web/`）文案修改。

## Capabilities

### New Capabilities

（无 — 不新增独立能力域。）

### Modified Capabilities

- `ai-chat`：补充产品级要求 — 个人设置页不得提供自定义 AI API Key 的配置入口；与 `AiConfig` 运行时加载、后端代理策略正交。

## Impact

- **Flutter**：`flutter/lib/features/settings/screens/settings_screen.dart`（及若存在的仅该区块引用的子组件）；可能涉及仅引用「AI 助手配置」文案的 widget 测试。
- **保留**：`flutter/lib/features/chat/services/ai_config.dart`（`load` / `saveApiKey` 等供聊天、计划等模块继续使用，除非设置页是唯一调用方且可删除 `saveApiKey` 的引用 — 以实现为准）。
- **后端**：无。
- **数据**：默认不迁移或擦除本地已存 Key；与「待确认」一致。
