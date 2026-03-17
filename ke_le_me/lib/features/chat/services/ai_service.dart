import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

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
      final response = await _dio.post<ResponseBody>(
        '/v1/chat/completions',
        data: {
          'model': config.model,
          'messages': messages,
          'tools': tools.isEmpty ? null : tools,
          'tool_choice': tools.isEmpty ? null : 'auto',
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
          'stream': true,
        }..removeWhere((_, v) => v == null),
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream;
      final buffer = StringBuffer();

      // 用于累积 tool_call arguments（可能分多个 chunk 到达）
      final Map<int, _ToolCallAccumulator> toolCallAccumulators = {};

      await for (final chunk in stream) {
        buffer.write(utf8.decode(chunk));
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
        msg = 'API 错误 ($status)';
        if (status == 401) msg = 'API Key 无效，请检查配置';
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
