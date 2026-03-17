import 'dart:convert';

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
        'function': {'name': name, 'arguments': jsonEncode(arguments)},
      };

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final fn = json['function'] as Map<String, dynamic>;
    final rawArgs = fn['arguments'];
    Map<String, dynamic> args;
    if (rawArgs is String) {
      try {
        args = jsonDecode(rawArgs) as Map<String, dynamic>;
      } catch (_) {
        args = {};
      }
    } else if (rawArgs is Map<String, dynamic>) {
      args = rawArgs;
    } else {
      args = {};
    }
    return ToolCall(
      id: json['id'] as String? ?? '',
      name: fn['name'] as String? ?? '',
      arguments: args,
    );
  }
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.done,
    this.toolCalls,
    this.toolCallId,
  });

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    List<ToolCall>? toolCalls,
    String? toolCallId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId ?? this.toolCallId,
    );
  }

  /// 转为 DeepSeek API 格式
  Map<String, dynamic> toApiMap() {
    final hasToolCalls = toolCalls != null && toolCalls!.isNotEmpty;
    final map = <String, dynamic>{
      'role': role.name,
      // assistant + tool_calls 时 content 必须为 null，空字符串会导致 400
      'content': hasToolCalls ? null : content,
    };
    if (hasToolCalls) {
      map['tool_calls'] = toolCalls!.map((t) => t.toJson()).toList();
    }
    if (toolCallId != null) {
      map['tool_call_id'] = toolCallId;
    }
    return map;
  }

  /// 转为持久化格式
  Map<String, dynamic> toStorageMap() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        if (toolCalls != null)
          'toolCalls': toolCalls!.map((t) => t.toJson()).toList(),
        if (toolCallId != null) 'toolCallId': toolCallId,
      };

  factory ChatMessage.fromStorageMap(Map<String, dynamic> map) {
    final roleStr = map['role'] as String;
    final statusStr = map['status'] as String? ?? 'done';
    final toolCallsList = map['toolCalls'] as List?;

    return ChatMessage(
      id: map['id'] as String,
      role: MessageRole.values.firstWhere((r) => r.name == roleStr,
          orElse: () => MessageRole.user),
      content: map['content'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: MessageStatus.values.firstWhere((s) => s.name == statusStr,
          orElse: () => MessageStatus.done),
      toolCalls: toolCallsList
          ?.map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
      toolCallId: map['toolCallId'] as String?,
    );
  }
}
