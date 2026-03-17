# 渴了么 — AI 健康助手对话功能 实施规格书

## 概述

为渴了么 App 新增 AI 健康助手对话模块，采用客户端直调 DeepSeek API 的 MVP 架构。模型通过 Function Calling 可直接操作 App 核心功能（记录喝水、调整目标等），实现真正的 Agent 能力。

---

## 一、架构设计

### 数据流

```
用户输入
  ↓
ChatProvider（组装 messages + tools）
  ↓
AiService（dio → DeepSeek API，SSE 流式）
  ↓ 返回文本 or tool_call
ChatProvider 判断：
  ├─ 文本 → 追加到 messages → UI 流式渲染
  └─ tool_call → 执行 FunctionRegistry → 结果回传模型 → 继续生成
```

### API Key 管理

通过 `--dart-define` 编译时注入，不进入版本库：

```bash
# 开发运行
flutter run -d macos --dart-define=DEEPSEEK_API_KEY=sk-xxxxx

# 在代码中读取
const apiKey = String.fromEnvironment('DEEPSEEK_API_KEY');
```

### 可扩展性设计

- `AiService` 通过 `AiConfig` 抽象模型配置，切换模型只改配置
- `FunctionRegistry` 注册制，新增 Function 不改现有代码
- `ChatStorageService` 接口化，MVP 用 SharedPreferences，后续可切数据库
- 后续加后端中转只需改 `AiConfig.baseUrl`，其余不动

---

## 二、新增文件结构

```
ke_le_me/lib/
├── features/
│   └── chat/
│       ├── models/
│       │   └── chat_message.dart        # 消息数据模型
│       ├── services/
│       │   ├── ai_config.dart           # API 配置（endpoint、model、key）
│       │   ├── ai_service.dart          # DeepSeek API 调用（dio + SSE）
│       │   ├── function_registry.dart   # Function Calling 注册与执行
│       │   └── chat_storage_service.dart # 对话持久化
│       ├── providers/
│       │   └── chat_provider.dart       # 对话状态管理
│       ├── widgets/
│       │   ├── chat_bubble.dart         # 消息气泡（用户/AI/系统）
│       │   ├── typing_indicator.dart    # AI 正在输入动画
│       │   └── suggestion_chips.dart    # 快捷建议标签
│       └── screens/
│           └── chat_screen.dart         # 对话页面
```

**修改现有文件：**

| 文件 | 变更 |
|------|------|
| `pubspec.yaml` | 新增 `dio: ^5.7.0` 依赖 |
| `main.dart` | 新增 `/chat` 路由 |
| `home_screen.dart` | Header 区域新增 AI 助手入口按钮 |

---

## 三、模型定义

### `chat_message.dart`

```dart
enum MessageRole { system, user, assistant, tool }

enum MessageStatus { sending, streaming, done, error }

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCall({required this.id, required this.name, required this.arguments});

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'function',
    'function': {'name': name, 'arguments': arguments},
  };

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final fn = json['function'] as Map<String, dynamic>;
    return ToolCall(
      id: json['id'] ?? '',
      name: fn['name'] ?? '',
      arguments: fn['arguments'] is String
          ? jsonDecode(fn['arguments'])
          : fn['arguments'] ?? {},
    );
  }
}

class ChatMessage {
  final String id;             // uuid
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final List<ToolCall>? toolCalls;    // assistant 消息可能包含
  final String? toolCallId;          // tool 角色消息需要

  // 构造函数、copyWith、toApiMap()、toStorageMap()、fromStorageMap()
}
```

**关键方法：**

- `toApiMap()` — 转为 DeepSeek API 格式（用于请求）
- `toStorageMap()` / `fromStorageMap()` — 用于 SharedPreferences 持久化

---

## 四、服务层

### 4.1 `ai_config.dart` — API 配置

```dart
class AiConfig {
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;

  const AiConfig({
    this.baseUrl = 'https://api.deepseek.com',
    this.apiKey = '',      // 从 --dart-define 读取
    this.model = 'deepseek-chat',
    this.temperature = 0.7,
    this.maxTokens = 2048,
  });

  /// 从编译时环境变量创建（MVP 方案）
  factory AiConfig.fromEnvironment() => const AiConfig(
    apiKey: String.fromEnvironment('DEEPSEEK_API_KEY'),
  );

  /// 未来切换到后端中转只需改这里
  // factory AiConfig.withBackend() => const AiConfig(
  //   baseUrl: 'https://your-api.example.com',
  //   apiKey: '',  // 后端处理鉴权
  // );
}
```

### 4.2 `ai_service.dart` — DeepSeek API 调用

**职责：** 仅负责 HTTP 通信，不持有状态。

```dart
class AiService {
  final Dio _dio;
  final AiConfig config;

  AiService({required this.config}) : _dio = Dio(BaseOptions(
    baseUrl: config.baseUrl,
    headers: {
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
    },
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));

  /// 流式发送消息，返回 SSE 事件流
  /// 每个事件是一个 delta 片段（文本或 tool_call）
  Stream<AiStreamEvent> sendMessageStream({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async* {
    // POST /chat/completions 
    // stream: true
    // 解析 SSE data: {...} 行
    // yield AiStreamEvent.text(delta) 或 AiStreamEvent.toolCall(...)
    // 遇到 [DONE] 时 yield AiStreamEvent.done()
  }

  void dispose() => _dio.close();
}

/// SSE 事件类型
sealed class AiStreamEvent {
  const AiStreamEvent();
}
class AiTextDelta extends AiStreamEvent {
  final String text;
  const AiTextDelta(this.text);
}
class AiToolCallDelta extends AiStreamEvent {
  final ToolCall toolCall;
  const AiToolCallDelta(this.toolCall);
}
class AiDone extends AiStreamEvent {
  final String? finishReason;
  const AiDone(this.finishReason);
}
class AiError extends AiStreamEvent {
  final String message;
  const AiError(this.message);
}
```

**SSE 解析要点：**
- 响应 `Content-Type: text/event-stream`
- 每行格式 `data: {"choices":[{"delta":{"content":"..."}}]}`
- `data: [DONE]` 表示结束
- tool_call 的 arguments 可能分多个 chunk 到达，需要累积拼接后再 JSON 解析

### 4.3 `function_registry.dart` — Function Calling

**设计：注册制 + 类型安全**

```dart
typedef FunctionHandler = Future<String> Function(Map<String, dynamic> args);

class FunctionDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;  // JSON Schema
  final FunctionHandler handler;

  const FunctionDefinition({...});

  Map<String, dynamic> toToolJson() => {
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': parameters,
    },
  };
}

class FunctionRegistry {
  final Map<String, FunctionDefinition> _functions = {};

  void register(FunctionDefinition fn) => _functions[fn.name] = fn;
  
  List<Map<String, dynamic>> get toolsJson =>
      _functions.values.map((f) => f.toToolJson()).toList();

  Future<String> execute(String name, Map<String, dynamic> args) async {
    final fn = _functions[name];
    if (fn == null) return '{"error": "未知工具: $name"}';
    try {
      return await fn.handler(args);
    } catch (e) {
      return '{"error": "$e"}';
    }
  }
}
```

**MVP 阶段注册的 Functions（在 ChatProvider 初始化时注册）：**

| Function | 描述 | 参数 | 调用 UserProvider 方法 |
|----------|------|------|----------------------|
| `add_drink` | 帮用户记录喝水 | `ml` (int, required), `type` (string, 图标), `desc` (string) | `userProvider.addDrink(ml, type: type, desc: desc)` |
| `get_today_progress` | 查询今日饮水进度 | 无 | 读取 `userProvider.todayMl` / `progress` / `logs` |
| `get_user_profile` | 查询用户基本信息 | 无 | 读取 `userProvider.profile` |
| `update_daily_goal` | 调整每日目标 | `goalMl` (int, required) | 修改 `profile.dailyGoalMl` → `userProvider.updateProfile()` |

**每个 Function 的 handler 返回值为 JSON 字符串**，回传给模型作为 tool role 消息的 content。

### 4.4 `chat_storage_service.dart` — 对话持久化

```dart
class ChatStorageService {
  static const _messagesKey = 'chat_messages';
  static const _summariesKey = 'chat_summaries';
  static const _maxStoredMessages = 50;     // 最多存储最近 50 条
  static const _maxSummaries = 10;          // 最多存储 10 条历史摘要

  /// 保存当前对话消息（只保留最近 N 条的 user + assistant）
  Future<void> saveMessages(List<ChatMessage> messages);

  /// 加载上次对话消息
  Future<List<ChatMessage>> loadMessages();

  /// 保存会话摘要（上一轮对话的一句话总结）
  Future<void> addSummary(String summary);

  /// 获取历史摘要（用于注入 system prompt）
  Future<List<String>> getSummaries();

  /// 清空对话记录
  Future<void> clear();
}
```

---

## 五、状态管理

### `chat_provider.dart`

**职责：** 串联 AiService、FunctionRegistry、ChatStorageService 和 UserProvider。

```dart
class ChatProvider extends ChangeNotifier {
  final AiService _aiService;
  final FunctionRegistry _registry;
  final ChatStorageService _storage;
  final UserProvider _userProvider;

  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  ChatProvider({
    required AiService aiService,
    required UserProvider userProvider,
  }) : _aiService = aiService,
       _userProvider = userProvider,
       _registry = FunctionRegistry(),
       _storage = ChatStorageService() {
    _registerFunctions();
  }
```

**核心流程 — `sendMessage(String text)`：**

```
1. 添加 user message 到 _messages
2. 设置 _isGenerating = true，notifyListeners()
3. 构建 system prompt（注入用户数据 + 历史摘要）
4. 组装 API messages（system + 最近 N 条 messages）
5. 调用 _aiService.sendMessageStream()
6. 监听 SSE 流：
   ├─ AiTextDelta → 追加到当前 assistant message.content → notifyListeners()（流式渲染）
   ├─ AiToolCallDelta → 收集完整 tool_call
   └─ AiDone →
       ├─ 如果有 tool_calls：
       │   a. 将 assistant message（含 tool_calls）加入 _messages
       │   b. 逐个执行 _registry.execute()
       │   c. 将每个执行结果作为 tool message 加入 _messages
       │   d. 再次调用 sendMessageStream()（让模型基于工具结果继续生成）
       └─ 如果无 tool_calls：
           a. 标记 message.status = done
           b. _isGenerating = false
           c. 保存到 _storage
           d. notifyListeners()
7. 错误处理 → AiError → 设置 _error，_isGenerating = false
```

**System Prompt 构建规则：**

```dart
String _buildSystemPrompt() {
  final p = _userProvider.profile;
  final todayMl = _userProvider.todayMl;
  final remaining = _userProvider.remainingMl;
  final pct = (_userProvider.progress * 100).round();
  final logs = _userProvider.logs;
  final streak = _userProvider.streakDays;
  final now = DateTime.now();
  final hour = now.hour;

  return '''
你是「渴了么」App 的 AI 健康饮水助手，名字叫「小渴」。

## 角色设定
- 专业但亲切，用简短的中文回答
- 关注用户的饮水健康，适时鼓励
- 可以回答饮水、健康饮品相关问题
- 当用户需要记录喝水或调整目标时，主动调用工具

## 用户信息
- 昵称：${p.nickname.isEmpty ? '用户' : p.nickname}
- 性别：${p.gender}
- 体重：${p.weight}kg
- 运动量：${p.activityLevel}
- 每日目标：${p.dailyGoalMl}ml
- 作息：${p.wakeTime} ~ ${p.bedTime}

## 今日状态（${now.month}月${now.day}日 ${hour}时）
- 已喝：${todayMl}ml（${pct}%）
- 剩余：${remaining}ml
- 打卡次数：${logs.length}
- 连续达标：${streak}天
${logs.isNotEmpty ? '- 最近记录：${logs.last.time} ${logs.last.description} ${logs.last.ml}ml' : '- 今天还没有喝水记录'}

## 回复规则
- 回复控制在 100 字以内，除非用户要求详细解释
- 用 emoji 增加亲和力，但不要过度
- 如果用户说喝了水但没指定量，默认 250ml
- 记录喝水后给出简短鼓励
''';
}
```

---

## 六、UI 规格

### 6.1 入口 — HomeScreen Header 新增按钮

在 `home_screen.dart` 的 `_buildHeader` 方法中，通知铃铛按钮左侧新增 AI 助手按钮：

```dart
_headerBtn(Icons.smart_toy_outlined, () => Navigator.pushNamed(context, '/chat')),
```

按钮样式与现有 `_headerBtn` 一致（36×36 圆形，`AppColors.bgSection` 背景）。

### 6.2 ChatScreen 布局

```
┌──────────────────────────────────┐
│  ← 返回    AI 健康助手    清空对话  │  AppBar
├──────────────────────────────────┤
│                                  │
│  ┌─ AI 气泡 ─────────────────┐  │
│  │ 👋 你好！我是小渴...       │  │
│  └───────────────────────────┘  │
│                                  │
│        ┌─ 用户气泡 ──────┐      │
│        │ 帮我记一杯咖啡   │      │
│        └─────────────────┘      │
│                                  │
│  ┌─ AI 气泡 ─────────────────┐  │
│  │ ☕ 已帮你记录咖啡 350ml！  │  │
│  │ 今天已喝 1200ml (52%)...  │  │
│  └───────────────────────────┘  │
│                                  │
│  ┌─ TypingIndicator ─────────┐  │  （AI 生成中显示）
│  │ ● ● ●                     │  │
│  └───────────────────────────┘  │
│                                  │
├──────────────────────────────────┤
│ [今天喝多少] [制定计划] [健康建议] │  SuggestionChips（无消息时显示）
├──────────────────────────────────┤
│  [  输入消息...          ] [发送] │  输入栏
└──────────────────────────────────┘
```

### 6.3 `chat_screen.dart`

```dart
class ChatScreen extends StatefulWidget {
  final UserProvider userProvider;
  const ChatScreen({super.key, required this.userProvider});
}
```

**页面结构：**
- `Scaffold` + `AppBar`（标题「AI 健康助手」，右侧清空按钮）
- `Column`:
  - `Expanded` → `ListView.builder`（消息列表，reverse: true）
  - 条件显示 `SuggestionChips`（当消息数 ≤ 1 时）
  - 底部输入栏（`TextField` + 发送按钮）

**状态管理：** 页面内创建 `ChatProvider`，在 `initState` 中初始化，`dispose` 中释放。

**初始消息：** 如果 `_storage` 无历史消息，自动插入一条 AI 欢迎语：
> 👋 你好！我是小渴，你的智能饮水助手。你可以问我任何关于喝水和健康的问题，也可以让我帮你记录喝水哦～

### 6.4 `chat_bubble.dart`

| 属性 | 用户气泡 | AI 气泡 |
|------|---------|---------|
| 对齐 | 右对齐 `CrossAxisAlignment.end` | 左对齐 `CrossAxisAlignment.start` |
| 背景色 | `AppColors.blue` | `AppColors.bgCard` |
| 文字色 | `Colors.white` | `AppColors.textPrimary` |
| 圆角 | 左上/左下/右上 16px，右下 4px | 右上/左下/右下 16px，左上 4px |
| 最大宽度 | `MediaQuery.of(context).size.width * 0.75` | 同左 |
| 头像 | 无 | 左侧蓝色圆圈内「渴」字（与 Header logo 一致） |
| 时间戳 | 气泡下方小字 `HH:mm` | 同左 |

**流式渲染：** AI 气泡文字实时更新（每次 `notifyListeners` 触发重建），末尾显示闪烁光标 `▍`（streaming 状态时）。

### 6.5 `typing_indicator.dart`

三个圆点交替缩放动画（`AnimationController` + `Interval` 交错），颜色 `AppColors.textHint`，仅在 `isGenerating && 当前 assistant message 为空` 时显示。

### 6.6 `suggestion_chips.dart`

横向滚动的标签列表，点击后自动发送对应文本：

```dart
const defaultSuggestions = [
  '今天该喝多少水？',
  '帮我制定喝水计划',
  '喝咖啡算喝水吗？',
  '我的饮水习惯怎么样？',
];
```

样式：`AppColors.blueLight` 背景 + `AppColors.blue` 文字，圆角 20px，水平间距 8px。

---

## 七、实施步骤（按顺序执行）

### Step 1：添加依赖
- 在 `pubspec.yaml` 添加 `dio: ^5.7.0`
- 运行 `flutter pub get`

### Step 2：创建 Models
- 创建 `features/chat/models/chat_message.dart`

### Step 3：创建 Services
- 创建 `features/chat/services/ai_config.dart`
- 创建 `features/chat/services/ai_service.dart`（含 SSE 解析）
- 创建 `features/chat/services/function_registry.dart`
- 创建 `features/chat/services/chat_storage_service.dart`

### Step 4：创建 Provider
- 创建 `features/chat/providers/chat_provider.dart`
- 实现完整的 send → stream → tool_call → 二次请求 闭环

### Step 5：创建 Widgets
- 创建 `features/chat/widgets/chat_bubble.dart`
- 创建 `features/chat/widgets/typing_indicator.dart`
- 创建 `features/chat/widgets/suggestion_chips.dart`

### Step 6：创建 Screen
- 创建 `features/chat/screens/chat_screen.dart`

### Step 7：集成到主应用
- `main.dart` 添加 `/chat` 路由
- `home_screen.dart` Header 新增 AI 助手按钮

### Step 8：平台配置
- macOS：确认 `DebugProfile.entitlements` 和 `Release.entitlements` 中有 `com.apple.security.network.client = true`（已有，用于 Google Fonts）
- Android：确认 `AndroidManifest.xml` 中有 `<uses-permission android:name="android.permission.INTERNET"/>` （Flutter 默认包含）

---

## 八、运行与测试

```bash
# 运行（macOS，注入 API Key）
flutter run -d macos --dart-define=DEEPSEEK_API_KEY=sk-your-key-here

# 运行（其他平台）
flutter run -d chrome --dart-define=DEEPSEEK_API_KEY=sk-your-key-here
flutter run -d <device_id> --dart-define=DEEPSEEK_API_KEY=sk-your-key-here
```

### 验收标准

1. **基础对话**：能发送消息并收到流式回复
2. **Function Calling**：说「帮我记一杯水 200ml」→ 模型调用 `add_drink` → HomeScreen 数据更新
3. **上下文感知**：模型知道用户的今日进度、体重、目标等信息
4. **对话持久化**：退出重进页面，历史消息仍在
5. **错误处理**：无网络时显示友好提示，API Key 缺失时显示配置提示
6. **UI 一致性**：对话页面风格与现有 App 统一（颜色、字体、圆角）

---

## 九、后续扩展（不在本次 MVP 范围）

- [ ] 接入后端中转（Express + 阿里云 FC），隐藏 API Key
- [ ] Markdown 渲染（AI 回复支持列表、加粗等格式）
- [ ] 图片/文件上传（体检报告分析）
- [ ] 会话摘要生成（跨会话长期记忆）
- [ ] 更多 Function：查询天气建议饮水量、分析近 7 日趋势
- [ ] 语音输入
