# 规格：AI 聊天

> 领域：backend + flutter · 版本：1.0.0 · 最后更新：2026-03-27

## 概述

AI 助手"小渴"基于 DeepSeek Chat 模型，通过后端代理 SSE 流式接口提供对话服务。支持 Function Calling（工具调用）、长期记忆（MemoryFact + SessionSummary）、多轮工具调用循环。

**架构**：Flutter → `POST /api/ai/chat`（SSE） → DeepSeek API

---

## 需求

### REQ-CHAT-01：流式对话

**场景 1：正常流式响应**
- Given 用户在聊天页输入消息并发送
- When `ChatProvider._doGenerate()` 向 `/api/ai/chat` 发起 SSE 请求
- Then 逐字流式显示助手回复，`TypingIndicator` 动画在流式期间显示

**场景 2：后端代理 SSE 转发**
- Given 后端收到 `/api/ai/chat` 请求（含 messages、tools、temperature、max_tokens）
- When 向 DeepSeek API 发起带 `stream: true` 的请求
- Then 将 SSE 事件直接管道传输给客户端，客户端断开时自动 abort 上游请求

**场景 3：非流式模式**
- Given 请求 body 中 `stream: false`
- When 服务端调用 DeepSeek
- Then 等待完整响应后以 JSON 格式返回

**场景 4：触发 AI 限流**
- Given 同一用户在 60 秒内已发起超过 10 次 `/api/ai/chat` 请求
- When 再次发起请求
- Then 返回 429，响应头含 `Retry-After`

---

### REQ-CHAT-02：Function Calling（工具调用）

**描述**：AI 可通过工具调用执行客户端操作，如记录饮水、设置提醒、修改目标、查询天气等。

**场景 1：AI 发起工具调用**
- Given AI 响应包含 `tool_calls` 字段
- When `ChatProvider._doGenerate()` 检测到工具调用
- Then 调用 `FunctionRegistry.execute(name, args)` 执行对应工具，将结果作为 `tool` 角色消息追加，继续下一轮生成

**场景 2：多工具并发调用**
- Given AI 在同一轮响应中发出多个 `tool_calls`
- When 工具处理器接收
- Then 按顺序依次执行，将所有结果追加后触发下一轮生成

**场景 3：工具调用循环上限**
- Given 对话陷入连续工具调用（无文字输出）
- When 达到 8 轮上限，或连续 3 轮只有工具调用无文字
- Then 强制压制工具定义，要求 AI 输出纯文字总结

**场景 4：工具调用/结果消息完整性校验**
- Given 历史消息中存在孤立的 `tool_calls`（无对应 `tool` 结果）或孤立结果
- When `_buildApiMessages()` 构建请求消息列表
- Then 剔除不完整的工具调用对，避免 DeepSeek 返回 400 错误

---

### REQ-CHAT-03：支持的工具（Function Definitions）

| 工具名称                 | 分类     | 说明                              |
|--------------------------|----------|-----------------------------------|
| `log_drink`              | 饮水     | 记录一次饮水（ml, icon, desc）    |
| `set_daily_goal`         | 饮水     | 设置每日饮水目标（ml）            |
| `get_today_stats`        | 饮水     | 获取今日饮水统计                  |
| `add_memory_fact`        | 记忆     | 添加用户记忆事实（category, content）|
| `get_memory_facts`       | 记忆     | 获取指定分类的记忆事实            |
| `delete_memory_fact`     | 记忆     | 删除指定记忆事实                  |
| `update_profile`         | 资料     | 更新用户资料字段                  |
| `get_profile`            | 资料     | 获取当前用户资料                  |
| `set_reminder`           | 提醒     | 设置一次性或周期提醒              |
| `cancel_reminder`        | 提醒     | 取消指定提醒                      |
| `get_weather`            | 天气     | 获取当前位置天气信息              |

---

### REQ-CHAT-04：长期记忆（MemoryFact）

**描述**：AI 在对话中发现有价值的用户信息时，通过工具写入 MemoryFact，在后续对话中注入系统提示。

**场景 1：添加记忆事实**
- Given AI 调用 `add_memory_fact`
- When `MemoryService.addFact(category, content, source)` 被调用
- Then 写入 Hive box `memory_facts`；容量上限 100 条，超出时淘汰最旧记录

**场景 2：注入记忆到系统提示**
- Given `SystemPromptBuilder.build()` 被调用
- When 构建系统提示
- Then 调用 `MemoryService.buildMemoryContext()`，注入最多 20 条记忆（每分类最多 5 条，按重要性+时间排序）

**场景 3：远程持久化**
- Given 用户已登录后端
- When 记忆写入本地后
- Then 通过 `POST /api/memory` 将事实同步到后端，支持跨设备恢复（规划中）

---

### REQ-CHAT-05：会话摘要（SessionSummary）

**描述**：用户结束对话时，如有足够内容则生成摘要，供后续对话的系统提示使用。

**场景 1：生成会话摘要**
- Given 用户关闭聊天页或切换 Tab，且本次会话中用户消息 ≥ 3 条
- When `ChatProvider.generateSummary()` 被调用
- Then 向 AI 发起非流式请求，要求生成 1 句话摘要，保存到 `SessionSummary`（Hive）

**场景 2：注入摘要到系统提示**
- Given 历史中有 SessionSummary 记录
- When 构建系统提示
- Then 注入最近 3 条摘要（带日期前缀）

**场景 3：摘要容量上限**
- Given Hive 中已有 30 条 SessionSummary
- When 添加新摘要
- Then 淘汰最早的记录，保持总数 ≤ 30 条

---

### REQ-CHAT-06：系统提示结构

**描述**：每次对话的系统提示由以下部分组合而成（`SystemPromptBuilder`）。

| 段落             | 内容                                                         |
|------------------|--------------------------------------------------------------|
| 角色定义         | AI 助手名称"小渴"，定位为专业健康饮水顾问                   |
| 用户资料         | 昵称、性别、体重、活动水平                                   |
| 今日状态         | 饮水量、目标、完成百分比、剩余量、打卡次数、连续天数         |
| 当前天气         | 温度、湿度、体感温度、UV 指数（可用时）                      |
| 长期记忆         | `MemoryService.buildMemoryContext()` 输出                    |
| 历史摘要         | `MemoryService.buildSummaryContext()` 输出（最近 3 条）       |
| 回复规则         | 100字以内、使用 emoji、默认记录 250ml、触发工具的场景规则    |

---

### REQ-CHAT-07：消息上下文窗口管理

**场景 1：长对话截断**
- Given 历史消息超过 20 条
- When `_buildApiMessages()` 构建请求
- Then 仅保留最近 20 条消息（排除 system 消息）

**场景 2：消息消毒（后端）**
- Given 客户端发送的消息中可能含有敏感字段
- When 后端 `sanitizeMessages()` 处理
- Then 移除消息中的敏感 key，仅转发必要字段到 DeepSeek

---

### REQ-CHAT-08：个人设置不提供 API Key 配置

**描述**：个人设置页（`SettingsScreen`）不得向用户提供输入、展示或保存第三方 LLM（如 DeepSeek）API Key 的区块（含「AI 助手配置」类标题、说明、输入框与「保存 API Key」等操作）。AI 对话等能力仍通过 `AiConfig.load()` 与既有存储/代理策略工作；本需求仅约束设置页 **UI**。

**场景 1：打开个人设置**
- Given 用户进入「个人设置」
- When 浏览整页内容
- Then 不出现用于 API Key 输入或保存的「AI 助手配置」类区块

**场景 2：其它设置区块**
- Given 用户使用基本设置、提醒开关/时间、「AI 健康档案」入口等
- When 操作上述区块
- Then 行为与移除 Key 配置入口前一致（除已移除的 API Key 配置外）

---

## API 端点

| 方法 | 路径            | 认证 | 限流       | 说明                         |
|------|-----------------|------|------------|------------------------------|
| POST | `/api/ai/chat`  | 是   | 10次/min   | SSE 流式/非流式 AI 对话代理  |

### 请求体

```json
{
  "messages": [
    { "role": "user" | "assistant" | "tool", "content": "...", "tool_calls": [...], "tool_call_id": "..." }
  ],
  "tools": [...],
  "temperature": 0.7,
  "max_tokens": 2048,
  "stream": true
}
```

### SSE 事件格式

| 事件类型        | Dart 类型         | 说明                      |
|-----------------|-------------------|---------------------------|
| 文本增量        | `AiTextDelta`     | `delta: String`           |
| 工具调用增量    | `AiToolCallDelta` | `index, id, name, argsChunk` |
| 完成            | `AiDone`          | 流结束                    |
| 错误            | `AiError`         | `message: String`         |

---

## 数据模型

### MemoryFact（Hive, typeId=0）

| 字段        | 类型     | 说明                                       |
|-------------|----------|--------------------------------------------|
| `id`        | String   | UUID                                       |
| `category`  | String   | health \| preference \| habit \| event \| reminder |
| `content`   | String   | 事实内容（≤1000字符）                      |
| `importance`| int      | 重要性（1-5）                              |
| `source`    | String   | chat \| manual \| system                  |
| `expiresAt` | DateTime?| 可选过期时间                               |
| `createdAt` | DateTime | 创建时间                                   |
| `updatedAt` | DateTime | 更新时间                                   |

### SessionSummary（Hive, typeId=1）

| 字段        | 类型     | 说明                |
|-------------|----------|---------------------|
| `id`        | String   | UUID                |
| `summary`   | String   | 摘要文本（≤2000字符）|
| `createdAt` | DateTime | 创建时间            |

---

## 客户端实现路径

- **AiService**：`flutter/lib/features/chat/services/ai_service.dart` — SSE 流解析
- **AiConfig**：`flutter/lib/features/chat/services/ai_config.dart` — 后端代理 vs 直连；个人设置页不提供 Key 配置（REQ-CHAT-08）
- **FunctionRegistry**：`flutter/lib/features/chat/services/function_registry.dart` — 工具注册与分发
- **ChatProvider**：`flutter/lib/features/chat/providers/chat_provider.dart` — 对话状态与循环
- **SystemPromptBuilder**：`flutter/lib/features/chat/providers/system_prompt_builder.dart` — 系统提示组装
- **MemoryService**：`flutter/lib/core/services/memory_service.dart` — 记忆 CRUD
- **Tool Handlers**：`flutter/lib/features/chat/providers/tool_handlers/` — drink, memory, profile, reminder, weather
