# 渴了么 — AI 聊天助手技术设计文档

## 一、功能概述

AI 聊天助手「小可」是渴了么 App 的核心交互界面，用户可以通过自然语言与小可对话，完成饮水记录、健康咨询、提醒设置等操作。

**核心能力：**
- 自然语言对话（流式响应）
- 函数调用（Function Calling / Tool Use）
- 长期记忆（跨会话记住用户健康信息）
- 会话摘要（退出时自动总结，下次上下文更连贯）
- 上下文感知（天气、今日饮水进度、用户画像等实时注入 system prompt）

---

## 二、架构总览

```
┌──────────────────────────────────────────────────────┐
│                    ChatScreen (UI)                     │
│  ┌─────────┐  ┌──────────┐  ┌──────────────────────┐ │
│  │ChatBubble│  │TypingInd.│  │  SuggestionChips     │ │
│  └─────────┘  └──────────┘  └──────────────────────┘ │
└───────────────────────┬──────────────────────────────┘
                        │ addListener / setState
                        ▼
┌──────────────────────────────────────────────────────┐
│              ChatProvider (ChangeNotifier)             │
│                                                       │
│  messages[]  ←→  ChatStorageService (持久化)           │
│  _doGenerate()  ←→  AiService (API 通信)              │
│  FunctionRegistry  ←→  ToolHandlers (工具执行)         │
│  SystemPromptBuilder (动态 system prompt)              │
└───────────────────────┬──────────────────────────────┘
                        │
           ┌────────────┼────────────┐
           ▼            ▼            ▼
     ┌──────────┐ ┌──────────┐ ┌──────────┐
     │AiService  │ │ToolHndlr │ │MemorySvc │
     │(DeepSeek) │ │(5 groups)│ │(Hive)    │
     └──────────┘ └──────────┘ └──────────┘
```

---

## 三、文件结构

```
lib/features/chat/
├── models/
│   └── chat_message.dart       # ChatMessage / ToolCall / MessageRole / MessageStatus
├── providers/
│   ├── chat_provider.dart      # 聊天状态管理核心
│   ├── system_prompt_builder.dart  # 动态构建 system prompt
│   └── tool_handlers/
│       ├── drink_tools.dart    # add_drink, get_today_progress
│       ├── memory_tools.dart   # save_health_note
│       ├── profile_tools.dart  # get_user_profile, update_daily_goal
│       ├── reminder_tools.dart # set_reminder
│       └── weather_tools.dart  # get_weather, get_daily_recommendation
├── screens/
│   └── chat_screen.dart        # 聊天页面 UI
├── services/
│   ├── ai_config.dart          # API 配置（key / baseUrl / model）
│   ├── ai_service.dart         # DeepSeek API SSE 流式通信
│   ├── chat_storage_service.dart # 消息 & 摘要持久化
│   └── function_registry.dart  # 工具注册中心
└── widgets/
    ├── chat_bubble.dart        # 消息气泡（Markdown 渲染）
    ├── suggestion_chips.dart   # 快捷建议标签
    └── typing_indicator.dart   # 打字动画指示器
```

**关联核心文件：**
| 文件 | 用途 |
|------|------|
| `core/services/memory_service.dart` | Hive 长期记忆存储 |
| `core/models/memory_fact.dart` | 记忆条目模型 |
| `core/models/custom_reminder.dart` | 自定义提醒模型 |
| `core/models/session_summary.dart` | 会话摘要模型 |

---

## 四、核心流程

### 4.1 消息发送与响应

```
用户输入 → sendMessage()
   ├── 1. 添加 user 消息到 _messages
   ├── 2. 设置 _isGenerating = true
   └── 3. 调用 _doGenerate()
         ├── 创建空的 assistant 占位消息（streaming 状态）
         ├── 构建 system prompt + API messages
         ├── 调用 AiService.sendMessageStream()
         │     ├── AiTextDelta  → 逐字追加到 assistant 消息
         │     ├── AiToolCallDelta → 累积到 toolCallsAccumulated
         │     ├── AiDone → 处理完成
         │     │   ├── 有 tool_calls → 执行工具 → 继续循环
         │     │   └── 无 tool_calls → 标记完成 → 保存 → 退出
         │     └── AiError → 显示错误 → 退出
         └── 循环最多 maxRounds 轮
```

### 4.2 工具调用循环（Tool Call Loop）

```
Round 1: API 返回 text + tool_calls
   → 执行工具，追加 tool 结果消息
   → shouldContinue = true

Round 2: API 基于工具结果继续生成
   → 可能返回更多 tool_calls 或纯文字
   → 纯文字 → 结束循环

连续 3 轮纯 tool_calls（无文字）：
   → 自动停止传递 tools 参数
   → 强制模型用文字回复

超过 maxRounds（8 轮）：
   → 执行一次不带 tools 的请求
   → 让模型生成文字总结，避免突兀中断
```

### 4.3 消息显示过滤

UI 层只显示有文字内容的消息，自动隐藏：
- `tool` 角色消息（API 内部通信）
- `system` 角色消息
- 空内容的 `assistant` 消息（仅含 tool_calls 的中间轮次）
- `streaming` 状态的空占位（用 TypingIndicator 替代）

---

## 五、System Prompt 设计

`SystemPromptBuilder` 每次请求动态构建，注入实时上下文：

| 区块 | 内容 | 数据来源 |
|------|------|---------|
| 角色设定 | 身份、能力边界、行为规则 | 硬编码 |
| 用户信息 | 昵称、性别、体重、运动量、目标、作息 | `UserProvider.profile` |
| 今日状态 | 已喝量、进度、打卡次数、连续天数 | `UserProvider` |
| 当前天气 | 温度、湿度、UV、AI 建议饮水量 | `UserProvider.weatherData` |
| 用户长期记忆 | 健康信息、偏好、习惯 | `MemoryService` (Hive) |
| 近期对话摘要 | 上次对话要点 | `MemoryService` (Hive) |
| 回复规则 | 字数限制、emoji 风格、默认水量 | 硬编码 |
| 工具调用规则 | 批量调用、轮次限制、文字收尾 | 硬编码 |

---

## 六、函数工具（Function Tools）

共 8 个工具，分 5 组：

### 饮水工具 (`drink_tools.dart`)
| 工具名 | 功能 | 参数 |
|--------|------|------|
| `add_drink` | 记录喝水量 | `ml` (required), `type`, `desc` |
| `get_today_progress` | 查询今日进度 | 无 |

### 用户资料 (`profile_tools.dart`)
| 工具名 | 功能 | 参数 |
|--------|------|------|
| `get_user_profile` | 查询用户信息 | 无 |
| `update_daily_goal` | 调整每日目标 | `goal_ml` (required) |

### 天气推荐 (`weather_tools.dart`)
| 工具名 | 功能 | 参数 |
|--------|------|------|
| `get_weather` | 获取当前天气 | 无 |
| `get_daily_recommendation` | 获取 AI 饮水推荐量 | 无 |

### 健康记忆 (`memory_tools.dart`)
| 工具名 | 功能 | 参数 |
|--------|------|------|
| `save_health_note` | 保存健康信息到长期记忆 | `content` (required), `category` (required), `importance` |

### 自定义提醒 (`reminder_tools.dart`)
| 工具名 | 功能 | 参数 |
|--------|------|------|
| `set_reminder` | 设置自定义提醒 | `title` (required), `datetime` (required), `repeat` |

---

## 七、数据流与持久化

### 消息存储 (`ChatStorageService`)

- **存储介质**：SharedPreferences (`chat_messages` key)
- **保存内容**：最近 50 条 `user` / `assistant` / `tool` 消息
- **存储时机**：每轮对话结束后
- **加载时机**：`ChatProvider.init()` 初始化时
- **孤儿清理**：保存和加载时自动清理无配对的 tool_calls / tool 消息

### 会话摘要

- 退出聊天页面时触发 `generateSummary()`（fire-and-forget）
- 调用 AiService 生成 50 字以内摘要
- 同时写入 SharedPreferences 和 Hive (`session_summaries` box)
- 下次对话时注入 system prompt

### 长期记忆 (`MemoryService`)

- **存储介质**：Hive (`memory_facts` box)
- **写入方式**：模型调用 `save_health_note` 工具时自动保存
- **读取方式**：构建 system prompt 时通过 `buildMemoryContext()` 注入
- **分类**：health / preference / habit / event

---

## 八、API 通信 (`AiService`)

### 配置
- **API**：DeepSeek Chat Completions（兼容 OpenAI 格式）
- **模型**：`deepseek-chat`
- **Base URL**：`https://api.deepseek.com`
- **流式**：SSE（Server-Sent Events）

### API Key 优先级
1. `--dart-define=DEEPSEEK_API_KEY=sk-xxx`（编译时注入）
2. SharedPreferences 保存的 key
3. 内置默认 key

### SSE 事件类型
| 事件 | 类 | 说明 |
|------|-----|------|
| 文本增量 | `AiTextDelta` | 逐 token 到达的文本 |
| 工具调用增量 | `AiToolCallDelta` | 工具调用参数（可能分多个 chunk） |
| 完成 | `AiDone` | 响应结束，含 `finishReason` |
| 错误 | `AiError` | API 或网络错误 |

### 请求体格式
```json
{
  "model": "deepseek-chat",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "帮我记录喝了一杯咖啡"},
    {"role": "assistant", "content": null, "tool_calls": [...]},
    {"role": "tool", "content": "{...}", "tool_call_id": "xxx"}
  ],
  "tools": [...],
  "tool_choice": "auto",
  "temperature": 0.7,
  "max_tokens": 2048,
  "stream": true
}
```

---

## 九、API Messages 构建规则 (`_buildApiMessages`)

发送给 API 的消息需要严格遵守格式，否则会返回 400 错误：

1. **窗口裁剪**：保留最近 20 条非 system 消息
2. **配对验证**：assistant + tool_calls 必须有对应的 tool 结果消息
3. **孤儿处理**：
   - 无配对 tool 结果的 assistant+tool_calls → 降级为纯文字消息
   - 无配对 assistant 的 tool 消息 → 直接丢弃
4. **content 规则**：
   - assistant + tool_calls 时 `content` 必须为 `null`（不能是空字符串）
   - tool 消息的 `content` 为 JSON 字符串
   - tool 消息必须有 `tool_call_id`

---

## 十、UI 组件

### ChatScreen
- `StatefulWidget`，初始化时创建 `ChatProvider` 并 `addListener`
- `ListView.builder` + `reverse: true` 实现倒序滚动
- `PopScope` 退出时触发会话摘要生成
- 工具执行回调：`onToolExecuted` 显示 SnackBar 轻提示

### ChatBubble
- 用户消息：蓝色圆角气泡，右对齐
- 助手消息：白色圆角气泡 + 左侧头像，Markdown 渲染（`flutter_markdown`）
- 错误消息：橙色背景
- Streaming 状态：末尾显示 `▍` 光标

### TypingIndicator
- 三点跳动动画，在模型生成但尚无文字输出时显示

### SuggestionChips
- 初始对话时显示快捷建议标签
- 点击直接发送预设问题

---

## 十一、已知设计决策与权衡

| 决策 | 原因 |
|------|------|
| 使用 DeepSeek 而非 Gemini | 支持 Function Calling、中文质量好、成本低 |
| 流式响应 (SSE) | 用户体验好，逐字显示，感知延迟低 |
| 最大 8 轮 tool call | 平衡工具调用灵活性和防死循环 |
| 连续 3 轮 tool-only 后撤回 tools | 强制模型用文字收尾，避免无限工具循环 |
| 超过 maxRounds 做无 tools 请求 | 比直接显示错误更优雅，让模型总结已执行的操作 |
| 消息持久化包含 tool 消息 | 保证加载后 API 消息配对完整，避免 400 错误 |
| 会话摘要 fire-and-forget | 不阻塞用户退出，失败也不影响体验 |
| system prompt 每次请求重建 | 保证上下文始终是最新的（饮水量、天气等实时变化） |

---

## 十二、错误处理

| 场景 | 处理方式 |
|------|---------|
| API Key 未配置 | 流中返回 `AiError`，显示配置提示 |
| API 401 | 显示「API Key 无效」 |
| API 429 | 显示「请求太频繁」 |
| API 400 | 显示具体错误信息（从响应体解析） |
| 网络超时 | 显示「网络超时」 |
| 工具执行异常 | 返回 `{"error": "..."}` 给模型，让模型转述 |
| JSON 解析失败 | 静默跳过该行 SSE 数据 |
| 工具调用死循环 | 连续 3 轮无文字后撤回 tools；超 8 轮做文字总结 |
