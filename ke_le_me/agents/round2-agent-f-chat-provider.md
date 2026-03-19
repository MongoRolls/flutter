# Round 2 · Agent F — ChatProvider Refactor + ChatScreen

**并行组**：Round 2（与 Agent E、G、H 同时执行，Round 1 已全部完成）  
**前提条件**：Round 1 的 tool_handlers/ 和 system_prompt_builder.dart 已创建  
**负责文件**：
- `lib/features/chat/providers/chat_provider.dart`（重构）
- `lib/features/chat/screens/chat_screen.dart`（修改）

**注意**：只修改上述 2 个文件，不要碰其他任何文件

---

你正在为 Flutter 项目「渴了么」(ke_le_me/) 实施 V2 升级的 Round 2。你的任务是重构 ChatProvider（拆分为组合模式）并修改 ChatScreen（添加 PopScope 摘要触发和工具执行轻提示）。

## 现有代码参考

**先读取以下文件了解现有结构**：
- `lib/features/chat/providers/chat_provider.dart`（当前约 370 行）
- `lib/features/chat/screens/chat_screen.dart`
- `lib/features/chat/services/ai_service.dart`（了解其接口，特别是是否有非流式调用方法）

**Round 1 已创建的文件**（可直接 import）：
- `lib/features/chat/providers/tool_handlers/drink_tools.dart` → `createDrinkTools(userProvider)`
- `lib/features/chat/providers/tool_handlers/profile_tools.dart` → `createProfileTools(userProvider)`
- `lib/features/chat/providers/tool_handlers/weather_tools.dart` → `createWeatherTools(userProvider)`
- `lib/features/chat/providers/tool_handlers/memory_tools.dart` → `createMemoryTools()`
- `lib/features/chat/providers/tool_handlers/reminder_tools.dart` → `createReminderTools()`
- `lib/features/chat/providers/system_prompt_builder.dart` → `SystemPromptBuilder.build(...)`

---

## 1. 重构 ChatProvider

**路径**：`lib/features/chat/providers/chat_provider.dart`

### 新增 import

```dart
import 'tool_handlers/drink_tools.dart';
import 'tool_handlers/profile_tools.dart';
import 'tool_handlers/weather_tools.dart';
import 'tool_handlers/memory_tools.dart';
import 'tool_handlers/reminder_tools.dart';
import 'system_prompt_builder.dart';
```

### 修改 _registerFunctions()

将现有内联的 4 个工具注册，替换为：

```dart
void _registerFunctions() {
  for (final fn in createDrinkTools(_userProvider)) {
    _registry.register(fn);
  }
  for (final fn in createProfileTools(_userProvider)) {
    _registry.register(fn);
  }
  for (final fn in createWeatherTools(_userProvider)) {
    _registry.register(fn);
  }
  for (final fn in createMemoryTools()) {
    _registry.register(fn);
  }
  for (final fn in createReminderTools()) {
    _registry.register(fn);
  }
}
```

### 修改 _buildSystemPrompt()

将现有的长字符串拼接，替换为：

```dart
String _buildSystemPrompt() {
  return SystemPromptBuilder.build(
    userProvider: _userProvider,
    weather: _userProvider.weatherData,
    prediction: _userProvider.goalPrediction,
  );
}
```

### 新增工具回调属性

在类的字段区域新增：

```dart
/// UI 层注册的工具执行回调，用于轻提示
void Function(String toolName, Map<String, dynamic> result)? onToolExecuted;
```

### 修改 _doGenerate() 中的工具执行部分

找到 `for (final tc in toolCallsAccumulated)` 循环，在执行工具并追加 tool 消息之后，添加回调通知：

```dart
for (final tc in toolCallsAccumulated) {
  final result = await _registry.execute(tc.name, tc.arguments);

  // 通知 UI 层（用于轻提示）
  if (onToolExecuted != null) {
    try {
      onToolExecuted!(tc.name, jsonDecode(result) as Map<String, dynamic>);
    } catch (_) {}
  }

  final toolMsg = ChatMessage(
    id: _uuid(),
    role: MessageRole.tool,
    content: result,
    timestamp: DateTime.now(),
    status: MessageStatus.done,
    toolCallId: tc.id,
  );
  _messages = [..._messages, toolMsg];
  notifyListeners();
}
```

### 新增 shouldGenerateSummary getter 和 generateSummary() 方法

在类末尾（`dispose()` 之前）新增：

```dart
/// 是否满足生成摘要的条件（用户至少发送了 3 条消息）
bool get shouldGenerateSummary {
  return _messages.where((m) => m.role == MessageRole.user).length >= 3;
}

/// 生成会话摘要并保存（供 PopScope 调用）
/// 使用 fire-and-forget 模式，失败时静默跳过
Future<void> generateSummary() async {
  try {
    final recentMessages = _messages
        .where((m) =>
            (m.role == MessageRole.user || m.role == MessageRole.assistant) &&
            m.content.isNotEmpty)
        .toList();

    if (recentMessages.length < 3) return;

    final toSummarize = recentMessages.length > 10
        ? recentMessages.sublist(recentMessages.length - 10)
        : recentMessages;

    final convText = toSummarize
        .map((m) =>
            '${m.role == MessageRole.user ? "用户" : "助手"}：${m.content}')
        .join('\n');

    final summaryPrompt =
        '请用一两句话（50字以内）总结以下对话的要点，重点关注用户的健康信息和需求：\n\n$convText';

    // 尝试非流式调用；如果 AiService 没有 sendSimpleMessage，
    // 则改为收集流式响应的完整内容
    String? summary;
    final buffer = StringBuffer();
    await for (final event in _aiService.sendMessageStream(
      messages: [
        {'role': 'system', 'content': '你是一个简洁的对话摘要助手。'},
        {'role': 'user', 'content': summaryPrompt},
      ],
      tools: [],
    )) {
      if (event is AiTextDelta) buffer.write(event.text);
      if (event is AiDone) summary = buffer.toString().trim();
    }

    if (summary != null && summary.isNotEmpty) {
      await _storage.addSummary(summary);
    }
  } catch (e) {
    debugPrint('Summary generation failed (non-blocking): $e');
  }
}
```

---

## 2. 修改 ChatScreen

**路径**：`lib/features/chat/screens/chat_screen.dart`

### 在 initState 中注册工具回调

找到 `_chatProvider.addListener(_onChatChanged);` 这一行，在其**之后**插入：

```dart
_chatProvider.onToolExecuted = (toolName, result) {
  if (!mounted) return;
  if (toolName == 'save_health_note' && result['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📝 已记住：${result['saved_content'] ?? ''}'),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  } else if (toolName == 'set_reminder' && result['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ 已设置提醒：${result['title'] ?? ''}'),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
};
```

### 用 PopScope 包裹 Scaffold

在 `build()` 方法中，找到 `return Scaffold(...)` 部分，将整个 Scaffold 包裹在 PopScope 里：

```dart
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      if (_chatProvider.shouldGenerateSummary) {
        // fire-and-forget，不等待完成再 pop
        unawaited(_chatProvider.generateSummary());
      }
      if (context.mounted) Navigator.of(context).pop();
    },
    child: Scaffold(
      // ... 现有 Scaffold 的所有内容保持不变
    ),
  );
}
```

需要在文件顶部新增：
```dart
import 'dart:async' show unawaited;
```

### 修改 AppBar 的返回按钮

找到现有的 leading `IconButton`（`Icons.arrow_back_ios_new_rounded`），将其 `onPressed` 改为：

```dart
onPressed: () {
  if (_chatProvider.shouldGenerateSummary) {
    unawaited(_chatProvider.generateSummary());
  }
  Navigator.pop(context);
},
```

---

## 重要约束

- 只修改上述 2 个文件
- 保留所有现有消息发送、流式处理、清空历史等逻辑完全不变
- `_userProvider.weatherData` 和 `_userProvider.goalPrediction` 由 Agent E 同步添加
- 检查 `ai_service.dart` 的实际接口——如果已经有非流式方法，优先使用；否则用上面的流式收集方案
- `AiTextDelta`、`AiDone` 等事件类型参考现有 `_doGenerate()` 中的用法
- 完成后运行 `flutter analyze` 检查这两个文件
