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
  }) : _aiService = aiService,
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
          content: '👋 你好！我是小可，你的智能饮水助手。你可以问我任何关于喝水和健康的问题，也可以让我帮你记录喝水哦～',
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
    const maxRounds = 8;
    var round = 0;
    var toolOnlyRounds = 0;

    try {
      while (round < maxRounds) {
        round++;

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
        // 连续 tool-only 轮次过多时，不再传 tools，强制模型用文字收尾
        final tools = toolOnlyRounds >= 3
            ? <Map<String, dynamic>>[]
            : _registry.toolsJson;

        final toolCallsAccumulated = <ToolCall>[];
        var shouldContinue = false;

        await for (final event in _aiService.sendMessageStream(
          messages: apiMessages,
          tools: tools,
        )) {
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
              assistantMsg = assistantMsg.copyWith(
                status: MessageStatus.done,
                toolCalls: toolCallsAccumulated,
              );
              _updateMessage(assistantMsg);

              for (final tc in toolCallsAccumulated) {
                final result = await _registry.execute(tc.name, tc.arguments);

                if (onToolExecuted != null) {
                  try {
                    onToolExecuted!(
                      tc.name,
                      jsonDecode(result) as Map<String, dynamic>,
                    );
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

              if (assistantMsg.content.isEmpty) {
                toolOnlyRounds++;
              } else {
                toolOnlyRounds = 0;
              }

              shouldContinue = true;
            } else {
              // 无 tool_calls：标记完成，退出循环
              // 如果内容为空（极端情况），不创建空消息
              if (assistantMsg.content.isEmpty) {
                _messages = _messages
                    .where((m) => m.id != assistantId)
                    .toList();
              } else {
                assistantMsg = assistantMsg.copyWith(
                  status: MessageStatus.done,
                );
                _updateMessage(assistantMsg);
              }
              _isGenerating = false;
              await _storage.saveMessages(_messages);
              notifyListeners();
            }
          } else if (event is AiError) {
            // 出错时：如果消息为空，移除占位；否则保留已有文字
            if (assistantMsg.content.isEmpty) {
              _messages = _messages.where((m) => m.id != assistantId).toList();
              final errorMsg = ChatMessage(
                id: _uuid(),
                role: MessageRole.assistant,
                content: '抱歉，出了点问题：${event.message}',
                timestamp: DateTime.now(),
                status: MessageStatus.error,
              );
              _messages = [..._messages, errorMsg];
            } else {
              assistantMsg = assistantMsg.copyWith(status: MessageStatus.error);
              _updateMessage(assistantMsg);
            }
            _error = event.message;
            _isGenerating = false;
            notifyListeners();
            return;
          }
        }

        if (!shouldContinue) break;
      }

      // 超过最大轮次：做一次不带 tools 的请求，让模型生成文字总结
      if (_isGenerating) {
        final summaryId = _uuid();
        var summaryMsg = ChatMessage(
          id: summaryId,
          role: MessageRole.assistant,
          content: '',
          timestamp: DateTime.now(),
          status: MessageStatus.streaming,
        );
        _messages = [..._messages, summaryMsg];
        notifyListeners();

        final systemPrompt = _buildSystemPrompt();
        final apiMessages = _buildApiMessages(systemPrompt);

        await for (final event in _aiService.sendMessageStream(
          messages: apiMessages,
          tools: [],
        )) {
          if (event is AiTextDelta) {
            summaryMsg = summaryMsg.copyWith(
              content: summaryMsg.content + event.text,
              status: MessageStatus.streaming,
            );
            _updateMessage(summaryMsg);
            notifyListeners();
          } else if (event is AiDone) {
            if (summaryMsg.content.isEmpty) {
              _messages = _messages.where((m) => m.id != summaryId).toList();
            } else {
              summaryMsg = summaryMsg.copyWith(status: MessageStatus.done);
              _updateMessage(summaryMsg);
            }
            break;
          } else if (event is AiError) {
            if (summaryMsg.content.isEmpty) {
              _messages = _messages.where((m) => m.id != summaryId).toList();
            }
            break;
          }
        }

        _isGenerating = false;
        await _storage.saveMessages(_messages);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      if (_isGenerating) {
        _isGenerating = false;
        notifyListeners();
      }
    }
  }

  void _updateMessage(ChatMessage updated) {
    _messages = _messages.map((m) => m.id == updated.id ? updated : m).toList();
  }

  String _buildSystemPrompt() {
    return SystemPromptBuilder.build(
      userProvider: _userProvider,
      weather: _userProvider.weatherData,
      prediction: _userProvider.goalPrediction,
    );
  }

  List<Map<String, dynamic>> _buildApiMessages(String systemPrompt) {
    final recent = _messages
        .where(
          (m) =>
              m.role != MessageRole.system &&
              !(m.role == MessageRole.assistant &&
                  m.content.isEmpty &&
                  (m.toolCalls == null || m.toolCalls!.isEmpty)),
        )
        .toList();
    final trimmed = recent.length > 20
        ? recent.sublist(recent.length - 20)
        : recent;

    // Collect tool_call IDs that have a matching tool-result message.
    final toolResultIds = <String>{};
    for (final m in trimmed) {
      if (m.role == MessageRole.tool && m.toolCallId != null) {
        toolResultIds.add(m.toolCallId!);
      }
    }

    // An assistant+tool_calls block is valid only when ALL of its tool_call
    // IDs have results. If any result is missing the whole block is stripped
    // to avoid partial-pair 400 errors.
    final validToolCallIds = <String>{};
    for (final m in trimmed) {
      if (m.role == MessageRole.assistant &&
          m.toolCalls != null &&
          m.toolCalls!.isNotEmpty) {
        final ids = m.toolCalls!.map((tc) => tc.id).toSet();
        if (ids.every(toolResultIds.contains)) {
          validToolCallIds.addAll(ids);
        }
      }
    }

    final apiMsgs = <Map<String, dynamic>>[];
    for (final m in trimmed) {
      if (m.role == MessageRole.assistant &&
          m.toolCalls != null &&
          m.toolCalls!.isNotEmpty) {
        if (m.toolCalls!.every((tc) => validToolCallIds.contains(tc.id))) {
          apiMsgs.add(m.toApiMap());
        } else if (m.content.isNotEmpty) {
          apiMsgs.add({'role': 'assistant', 'content': m.content});
        }
      } else if (m.role == MessageRole.tool) {
        if (m.toolCallId != null && validToolCallIds.contains(m.toolCallId)) {
          apiMsgs.add(m.toApiMap());
        }
      } else {
        apiMsgs.add(m.toApiMap());
      }
    }

    return [
      {'role': 'system', 'content': systemPrompt},
      ...apiMsgs,
    ];
  }

  Future<void> clearHistory() async {
    await _storage.clear();
    _messages = [
      ChatMessage(
        id: _uuid(),
        role: MessageRole.assistant,
        content: '👋 你好！我是小可，你的智能饮水助手。你可以问我任何关于喝水和健康的问题，也可以让我帮你记录喝水哦～',
        timestamp: DateTime.now(),
        status: MessageStatus.done,
      ),
    ];
    _error = null;
    _isGenerating = false;
    notifyListeners();
  }

  // 使用计数器 + 时间戳避免同一微秒内生成重复 ID
  int _uuidCounter = 0;
  String _uuid() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_uuidCounter++}';

  /// 是否满足生成摘要的条件（用户至少发送了 3 条消息）
  bool get shouldGenerateSummary {
    return _messages.where((m) => m.role == MessageRole.user).length >= 3;
  }

  /// 生成会话摘要并保存（供 PopScope 调用）
  /// 使用 fire-and-forget 模式，失败时静默跳过
  Future<void> generateSummary() async {
    try {
      final recentMessages = _messages
          .where(
            (m) =>
                (m.role == MessageRole.user ||
                    m.role == MessageRole.assistant) &&
                m.content.isNotEmpty,
          )
          .toList();

      if (recentMessages.length < 3) return;

      final toSummarize = recentMessages.length > 10
          ? recentMessages.sublist(recentMessages.length - 10)
          : recentMessages;

      final convText = toSummarize
          .map(
            (m) => '${m.role == MessageRole.user ? "用户" : "助手"}：${m.content}',
          )
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
