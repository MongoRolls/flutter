import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/models/user_profile.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/function_registry.dart';
import '../services/chat_storage_service.dart';

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
  })  : _aiService = aiService,
        _userProvider = userProvider,
        _registry = FunctionRegistry(),
        _storage = ChatStorageService() {
    _registerFunctions();
  }

  void _registerFunctions() {
    _registry.register(FunctionDefinition(
      name: 'add_drink',
      description: '帮用户记录喝水量',
      parameters: {
        'type': 'object',
        'properties': {
          'ml': {
            'type': 'integer',
            'description': '喝水量，单位毫升',
          },
          'type': {
            'type': 'string',
            'description': '饮品类型图标，如 💧 水、☕ 咖啡、🍵 茶等',
          },
          'desc': {
            'type': 'string',
            'description': '饮品描述，如 温水、咖啡、绿茶等',
          },
        },
        'required': ['ml'],
      },
      handler: (args) async {
        final ml = (args['ml'] as num?)?.toInt() ?? 0;
        final type = args['type'] as String? ?? '💧';
        final desc = args['desc'] as String? ?? '喝水';
        await _userProvider.addDrink(ml, type: type, desc: desc);
        final pct = (_userProvider.progress * 100).round();
        return jsonEncode({
          'success': true,
          'recorded_ml': ml,
          'today_total_ml': _userProvider.todayMl,
          'daily_goal_ml': _userProvider.profile.dailyGoalMl,
          'progress_percent': pct,
          'message': '成功记录 $desc ${ml}ml，今日共 ${_userProvider.todayMl}ml（$pct%）',
        });
      },
    ));

    _registry.register(FunctionDefinition(
      name: 'get_today_progress',
      description: '查询今日饮水进度',
      parameters: {
        'type': 'object',
        'properties': {},
      },
      handler: (args) async {
        final pct = (_userProvider.progress * 100).round();
        final logs = _userProvider.logs;
        return jsonEncode({
          'today_ml': _userProvider.todayMl,
          'daily_goal_ml': _userProvider.profile.dailyGoalMl,
          'remaining_ml': _userProvider.remainingMl,
          'progress_percent': pct,
          'log_count': logs.length,
          'recent_log': logs.isNotEmpty
              ? '${logs.last.time} ${logs.last.description} ${logs.last.ml}ml'
              : '暂无记录',
          'streak_days': _userProvider.streakDays,
        });
      },
    ));

    _registry.register(FunctionDefinition(
      name: 'get_user_profile',
      description: '查询用户基本信息和健康数据',
      parameters: {
        'type': 'object',
        'properties': {},
      },
      handler: (args) async {
        final p = _userProvider.profile;
        return jsonEncode({
          'nickname': p.nickname.isEmpty ? '用户' : p.nickname,
          'gender': p.gender,
          'weight_kg': p.weight,
          'activity_level': p.activityLevel,
          'daily_goal_ml': p.dailyGoalMl,
          'recommended_goal_ml': p.recommendedGoal,
          'wake_time': p.wakeTime,
          'bed_time': p.bedTime,
          'reminder_interval_min': p.reminderIntervalMin,
          'streak_days': _userProvider.streakDays,
        });
      },
    ));

    _registry.register(FunctionDefinition(
      name: 'update_daily_goal',
      description: '调整用户每日饮水目标',
      parameters: {
        'type': 'object',
        'properties': {
          'goal_ml': {
            'type': 'integer',
            'description': '新的每日饮水目标，单位毫升',
          },
        },
        'required': ['goal_ml'],
      },
      handler: (args) async {
        final goalMl = (args['goal_ml'] as num?)?.toInt() ?? 2000;
        final clamped = goalMl.clamp(500, 5000);
        final newProfile = UserProfile(
          nickname: _userProvider.profile.nickname,
          gender: _userProvider.profile.gender,
          activityLevel: _userProvider.profile.activityLevel,
          weight: _userProvider.profile.weight,
          dailyGoalMl: clamped,
          wakeTime: _userProvider.profile.wakeTime,
          bedTime: _userProvider.profile.bedTime,
          reminderIntervalMin: _userProvider.profile.reminderIntervalMin,
          reminderStyle: _userProvider.profile.reminderStyle,
          notificationsEnabled: _userProvider.profile.notificationsEnabled,
          onboardingCompleted: _userProvider.profile.onboardingCompleted,
        );
        _userProvider.updateProfile(newProfile);
        return jsonEncode({
          'success': true,
          'new_goal_ml': clamped,
          'message': '每日饮水目标已更新为 ${clamped}ml',
        });
      },
    ));
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

## 今日状态（${now.month}月${now.day}日 $hour时）
- 已喝：${todayMl}ml（$pct%）
- 剩余：${remaining}ml
- 打卡次数：${logs.length}
- 连续达标：$streak天
${logs.isNotEmpty ? '- 最近记录：${logs.last.time} ${logs.last.description} ${logs.last.ml}ml' : '- 今天还没有喝水记录'}

## 回复规则
- 回复控制在 100 字以内，除非用户要求详细解释
- 用 emoji 增加亲和力，但不要过度
- 如果用户说喝了水但没指定量，默认 250ml
- 记录喝水后给出简短鼓励
''';
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

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}
