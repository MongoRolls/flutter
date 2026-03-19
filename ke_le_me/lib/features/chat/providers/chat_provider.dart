import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/providers/user_provider.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/function_registry.dart';
import '../services/chat_storage_service.dart';
import 'tool_handlers/drink_tools.dart';
import 'tool_handlers/profile_tools.dart';
import 'tool_handlers/weather_tools.dart';
import 'tool_handlers/memory_tools.dart';
import 'tool_handlers/reminder_tools.dart';
import 'system_prompt_builder.dart';

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

  /// UI 层注册的工具执行回调，用于轻提示
  void Function(String toolName, Map<String, dynamic> result)? onToolExecuted;

  ChatProvider({
    required AiService aiService,
    required UserProvider userProvider,
  })  : _aiService = aiService,
        _userProvider = userProvider,
        _registry = FunctionRegistry(),
        _storage = ChatStorageService() {
    _registerFunctions();
  }

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

  /// 加载历史消息；若无历史则插入欢迎语
  Future<void> init() async {
    final stored = await _storage.loadMessages();
    if (stored.isEmpty) {
      _messages = [
        ChatMessage(
          id: _uuid(),
          role: MessageRole.assistant,
          content: '👋 你好！我是小渴，你的智能饮水助手。你可以问我任何关于喝水和健康的问题，也可以让我帮你记录喝水哦～',
          timestamp: DateTime.now(),
          status: MessageStatus.done,
        ),
      ];
    } else {
      _messages = stored;
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

    _error = null;

    // 添加用户消息
    final userMsg = ChatMessage(
      id: _uuid(),
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.done,
    );
    _messages = [..._messages, userMsg];
    _isGenerating = true;
    notifyListeners();

    await _doGenerate();
  }

  Future<void> _doGenerate() async {
    // 添加占位 assistant 消息（streaming）
    final assistantId = _uuid();
    var assistantMsg = ChatMessage(
      id: assistantId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: MessageStatus.streaming,
    );
    _messages = [..._messages, assistantMsg];
    notifyListeners();

    final systemPrompt = _buildSystemPrompt();
    final apiMessages = _buildApiMessages(systemPrompt);
    final tools = _registry.toolsJson;

    final toolCallsAccumulated = <ToolCall>[];

    await for (final event
        in _aiService.sendMessageStream(messages: apiMessages, tools: tools)) {
      if (event is AiTextDelta) {
        assistantMsg = assistantMsg.copyWith(
          content: assistantMsg.content + event.text,
          status: MessageStatus.streaming,
        );
        _updateMessage(assistantMsg);
        notifyListeners();
      } else if (event is AiToolCallDelta) {
        toolCallsAccumulated.add(event.toolCall);
      } else if (event is AiDone) {
        if (toolCallsAccumulated.isNotEmpty) {
          // 有 tool_calls：标记 assistant 消息并执行工具
          assistantMsg = assistantMsg.copyWith(
            status: MessageStatus.done,
            toolCalls: toolCallsAccumulated,
          );
          _updateMessage(assistantMsg);

          // 执行每个工具并追加 tool 消息
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

          // 二次调用，让模型基于工具结果继续生成
          await _doGenerate();
          return;
        } else {
          // 无 tool_calls：标记完成
          assistantMsg = assistantMsg.copyWith(status: MessageStatus.done);
          _updateMessage(assistantMsg);
          _isGenerating = false;
          await _storage.saveMessages(_messages);
          notifyListeners();
        }
      } else if (event is AiError) {
        assistantMsg = assistantMsg.copyWith(
          content: assistantMsg.content.isEmpty
              ? '抱歉，出了点问题：${event.message}'
              : assistantMsg.content,
          status: MessageStatus.error,
        );
        _updateMessage(assistantMsg);
        _error = event.message;
        _isGenerating = false;
        notifyListeners();
      }
    }
  }

  void _updateMessage(ChatMessage updated) {
    _messages = _messages
        .map((m) => m.id == updated.id ? updated : m)
        .toList();
  }

  String _buildSystemPrompt() {
    return SystemPromptBuilder.build(
      userProvider: _userProvider,
      weather: _userProvider.weatherData,
      prediction: _userProvider.goalPrediction,
    );
  }

  List<Map<String, dynamic>> _buildApiMessages(String systemPrompt) {
    // 保留最近 20 条可见消息（user/assistant/tool）
    // 过滤掉空内容的 streaming 占位消息（尚未收到任何回复的 assistant 消息）
    final recent = _messages
        .where((m) =>
            m.role != MessageRole.system &&
            !(m.role == MessageRole.assistant &&
                m.content.isEmpty &&
                (m.toolCalls == null || m.toolCalls!.isEmpty)))
        .toList();
    final trimmed = recent.length > 20 ? recent.sublist(recent.length - 20) : recent;

    return [
      {'role': 'system', 'content': systemPrompt},
      ...trimmed.map((m) => m.toApiMap()),
    ];
  }

  Future<void> clearHistory() async {
    await _storage.clear();
    _messages = [
      ChatMessage(
        id: _uuid(),
        role: MessageRole.assistant,
        content: '👋 你好！我是小渴，你的智能饮水助手。你可以问我任何关于喝水和健康的问题，也可以让我帮你记录喝水哦～',
        timestamp: DateTime.now(),
        status: MessageStatus.done,
      ),
    ];
    _error = null;
    _isGenerating = false;
    notifyListeners();
  }

  String _uuid() => DateTime.now().microsecondsSinceEpoch.toString();

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

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}
