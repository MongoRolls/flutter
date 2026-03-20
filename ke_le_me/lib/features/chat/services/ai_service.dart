import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'ai_config.dart';
import '../models/chat_message.dart';

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

class AiService {
  final Dio _dio;
  final AiConfig config;

  AiService({required this.config})
      : _dio = Dio(BaseOptions(
          baseUrl: config.baseUrl,
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  /// 流式发送消息，返回 SSE 事件流
  Stream<AiStreamEvent> sendMessageStream({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async* {
    if (config.apiKey.isEmpty) {
      yield const AiError('API Key 未配置，请使用 --dart-define=DEEPSEEK_API_KEY=sk-xxx 启动');
      return;
    }

    try {
      final requestBody = {
        'model': config.model,
        'messages': messages,
        'tools': tools.isEmpty ? null : tools,
        'tool_choice': tools.isEmpty ? null : 'auto',
        'temperature': config.temperature,
        'max_tokens': config.maxTokens,
        'stream': true,
      }..removeWhere((_, v) => v == null);

      debugPrint('=== DeepSeek API Request ===');
      debugPrint('messages count: ${messages.length}');
      for (final m in messages) {
        final role = m['role'];
        final content = m['content'];
        final toolCalls = m['tool_calls'];
        final toolCallId = m['tool_call_id'];
        debugPrint('  [$role] content=${content == null ? 'null' : '"${content.toString().length > 60 ? content.toString().substring(0, 60) + "..." : content}"'}${toolCalls != null ? ' tool_calls=${(toolCalls as List).length}' : ''}${toolCallId != null ? ' tool_call_id=$toolCallId' : ''}');
      }

      final response = await _dio.post<ResponseBody>(
        '/v1/chat/completions',
        data: requestBody,
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream;
      final buffer = StringBuffer();

      // 用于累积 tool_call arguments（可能分多个 chunk 到达）
      final Map<int, _ToolCallAccumulator> toolCallAccumulators = {};

      await for (final chunk in utf8.decoder.bind(stream)) {
        buffer.write(chunk);
        final raw = buffer.toString();
        buffer.clear();

        // 按行处理 SSE
        final lines = raw.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();

          // 最后一行可能不完整，放回 buffer
          if (i == lines.length - 1 && !raw.endsWith('\n')) {
            buffer.write(line);
            break;
          }

          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();

          if (data == '[DONE]') {
            // 所有 tool_call 累积完毕，发出事件
            for (final acc in toolCallAccumulators.values) {
              final toolCall = acc.build();
              if (toolCall != null) yield AiToolCallDelta(toolCall);
            }
            yield const AiDone(null);
            return;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices == null || choices.isEmpty) continue;

            final choice = choices[0] as Map<String, dynamic>;
            final finishReason = choice['finish_reason'] as String?;
            final delta = choice['delta'] as Map<String, dynamic>?;
            if (delta == null) {
              if (finishReason != null && finishReason != 'null') {
                for (final acc in toolCallAccumulators.values) {
                  final toolCall = acc.build();
                  if (toolCall != null) yield AiToolCallDelta(toolCall);
                }
                yield AiDone(finishReason);
                return;
              }
              continue;
            }

            // 文本 delta
            final content = delta['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield AiTextDelta(content);
            }

            // tool_calls delta
            final toolCallsRaw = delta['tool_calls'] as List?;
            if (toolCallsRaw != null) {
              for (final tc in toolCallsRaw) {
                final tcMap = tc as Map<String, dynamic>;
                final index = tcMap['index'] as int? ?? 0;
                final acc = toolCallAccumulators.putIfAbsent(
                    index, () => _ToolCallAccumulator());

                final id = tcMap['id'] as String?;
                if (id != null) acc.id = id;

                final fn = tcMap['function'] as Map<String, dynamic>?;
                if (fn != null) {
                  final name = fn['name'] as String?;
                  if (name != null) acc.name = name;
                  final args = fn['arguments'] as String?;
                  if (args != null) acc.argumentsBuffer.write(args);
                }
              }
            }
          } catch (e) {
            // 跳过解析失败的行
          }
        }
      }

      // 流结束但没有收到 [DONE]
      for (final acc in toolCallAccumulators.values) {
        final toolCall = acc.build();
        if (toolCall != null) yield AiToolCallDelta(toolCall);
      }
      yield const AiDone(null);
    } on DioException catch (e) {
      String msg;
      if (e.response != null) {
        final status = e.response!.statusCode;
        // Try to extract the actual error message from response body
        String? apiErrMsg;
        try {
          final body = e.response!.data;
          if (body is Map) {
            final err = body['error'];
            if (err is Map) apiErrMsg = err['message'] as String?;
          } else if (body is String && body.isNotEmpty) {
            final decoded = jsonDecode(body) as Map?;
            final err = decoded?['error'];
            if (err is Map) apiErrMsg = err['message'] as String?;
          }
        } catch (_) {}
        debugPrint('DeepSeek API $status error: $apiErrMsg\nraw: ${e.response?.data}');
        msg = 'API 错误 ($status)${apiErrMsg != null ? ': $apiErrMsg' : ''}';
        if (status == 401) msg = 'API Key 无效或已过期，请在设置中更换 Key';
        if (status == 400) msg = 'API 请求格式错误${apiErrMsg != null ? ': $apiErrMsg' : ''}';
        if (status == 429) msg = '请求太频繁，请稍后再试';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        msg = '网络超时，请检查网络连接';
      } else {
        msg = '网络错误：${e.message ?? '未知错误'}';
      }
      yield AiError(msg);
    } catch (e) {
      yield AiError('未知错误：$e');
    }
  }

  void dispose() => _dio.close();
}

class _ToolCallAccumulator {
  String id = '';
  String name = '';
  final StringBuffer argumentsBuffer = StringBuffer();

  ToolCall? build() {
    if (name.isEmpty) return null;
    Map<String, dynamic> args;
    try {
      final raw = argumentsBuffer.toString();
      args = raw.isEmpty ? {} : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      args = {};
    }
    return ToolCall(id: id, name: name, arguments: args);
  }
}
