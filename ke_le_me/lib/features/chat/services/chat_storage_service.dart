import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/session_summary.dart';
import '../models/chat_message.dart';

class ChatStorageService {
  static const _messagesKey = 'chat_messages';
  static const _summariesKey = 'chat_summaries';
  static const _maxStoredMessages = 50;
  static const _maxSummaries = 10;

  /// 保存当前对话消息（只保留最近 N 条的 user + assistant）
  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = messages
        .where((m) =>
            m.role == MessageRole.user || m.role == MessageRole.assistant)
        .toList();
    final trimmed = filtered.length > _maxStoredMessages
        ? filtered.sublist(filtered.length - _maxStoredMessages)
        : filtered;
    final json = jsonEncode(trimmed.map((m) => m.toStorageMap()).toList());
    await prefs.setString(_messagesKey, json);
  }

  /// 加载上次对话消息
  Future<List<ChatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ChatMessage.fromStorageMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 保存会话摘要
  Future<void> addSummary(String summary) async {
    // 保留现有 SharedPreferences 逻辑（兼容性）
    final prefs = await SharedPreferences.getInstance();
    final summaries = await getSummaries();
    summaries.add(summary);
    if (summaries.length > _maxSummaries) {
      summaries.removeRange(0, summaries.length - _maxSummaries);
    }
    await prefs.setString(_summariesKey, jsonEncode(summaries));

    // V2: 同时写入 Hive SessionSummary box
    try {
      final box = Hive.box<SessionSummary>('session_summaries');
      final sessionSummary = SessionSummary(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        summary: summary,
        date: DateTime.now(),
        topics: [],
      );
      await box.put(sessionSummary.id, sessionSummary);

      // Hive 上限 30 条，超出则删除最旧的
      if (box.length > 30) {
        final sorted = box.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        for (var i = 0; i < box.length - 30; i++) {
          await sorted[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to save summary to Hive: $e');
    }
  }

  /// 获取历史摘要
  Future<List<String>> getSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_summariesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// 清空对话记录
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
  }
}
