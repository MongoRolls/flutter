## Context

Flutter 客户端通过 `AiConfig` 合并 dart-define、本地存储与后端代理等来源决定 AI 请求路径。历史上个人设置页曾提供用户输入自定义 API Key 的入口；产品现要求从设置页收敛该入口，避免在「个人设置」暴露 Key 管理与保存流程。聊天、计划等仍通过 `AiConfig.load()` 使用现有加载逻辑。

## Goals / Non-Goals

**Goals:**

- 在 `SettingsScreen` 中移除「AI 助手配置」相关 UI 与仅服务该 UI 的代码路径。
- 保持其余设置区块（基本设置、提醒、AI 健康档案入口等）行为不变。
- 工程可分析、可构建：`flutter analyze` 无因本次删除产生的新问题；相关测试更新后 `flutter test` 通过。

**Non-Goals:**

- 不删除或重写 `AiConfig` 核心加载逻辑（除非设置页删除后 `saveApiKey` 等无任何引用，再按需清理 dead API）。
- 不强制清除用户曾保存的本地自定义 Key（产品决策另议）。
- 不修改 `web/` 官网或主规格归档（`openspec/specs/*.md`）除非后续 `/opsx:archive` 流程合并 delta。

## Decisions

1. **仅移除设置页入口，不默认清除数据**  
   **理由**：需求明确「不在本需求中擅自清除用户数据」；保留 `AiConfig.load()` 对既有存储的读取，避免升级后行为突变。  
   **备选**：升级时清除 Key — 需产品确认，本变更不采纳。

2. **`AiConfig.saveApiKey` 是否保留**  
   **理由**：若删除设置页后全仓库无调用，可删除或保留为内部/未来调试入口；优先删除未使用 API 以通过静态分析。若仍存在其它入口（如隐藏调试页），则保留 `saveApiKey` 实现。

3. **规格归属 `ai-chat`**  
   **理由**：主规格 `openspec/specs/ai-chat.md` 已列出 `AiConfig` 与客户端路径；「设置页不提供 Key」属于 AI 能力与配置暴露边界，放在 `ai-chat` delta 一致。

## Risks / Trade-offs

- **[风险] 删除不彻底导致编译错误或残留引用** → **缓解**：删除 `_buildApiKeySettings`、`_saveApiKey`、`_apiKeyController` 等后全量 `flutter analyze`，并 grep `saveApiKey` / `AiConfig` 在 `settings_screen` 的引用。
- **[风险] 测试仍查找已删除文案** → **缓解**：grep「AI 助手配置」「保存 API Key」等并更新测试。
- **[权衡] 用户仍可能通过旧版本写入的 Key 继续使用直连** → 与产品「仅隐藏入口」一致；若需禁止直连需另案。

## Migration Plan

- 发布即生效：用户升级后设置页不再显示该区块；无服务端迁移。
- **回滚**：恢复设置页相关 UI 与状态（若需热修）。

## Open Questions

1. 移除设置页后，是否仍允许通过 **调试入口 / 首次引导** 覆盖 API Key？若否，是否需要在某次升级 **清除已保存的自定义 Key**？
2. 「AI 健康档案」是否必须长期保留在设置页？（当前按保留处理。）
3. 是否需要在产品文档或主规格中注明「Key 仅内置 / 后端代理」？（本变更的 delta 已记录能力要求，主规格归档时再合并。）
