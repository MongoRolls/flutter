import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import '../models/care_contact.dart';
import '../models/care_record.dart';

/// 心连心模块的状态管理
class HeartProvider extends ChangeNotifier {
  List<CareContact> _contacts = [];
  List<CareRecord> _records = [];

  List<CareContact> get contacts => List.unmodifiable(_contacts);
  List<CareRecord> get records => List.unmodifiable(_records);

  /// 是否已发送过关怀（用于成就解锁判断）
  bool get hasSentCare => _records.any((r) => r.fromLabel == '你');

  /// 初始化加载
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载联系人
      final contactsJson = prefs.getString('care_contacts');
      if (contactsJson != null) {
        final list = jsonDecode(contactsJson) as List;
        _contacts = list.map((e) => CareContact.fromMap(e)).toList();
      } else {
        // 首次使用：加载预置联系人
        _contacts = CareContact.defaults;
        await _saveContacts(prefs);
      }

      // 加载关怀记录
      final recordsJson = prefs.getString('care_records');
      if (recordsJson != null) {
        final list = jsonDecode(recordsJson) as List;
        _records = list.map((e) => CareRecord.fromMap(e)).toList();
      } else {
        _records = CareRecord.mockRecords;
        await _saveRecords(prefs);
      }

      // 每日刷新联系人 mock 水量
      _refreshMockWaterIfNeeded(prefs);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading heart data: $e');
    }
  }

  /// 每日刷新联系人 mock 水量
  void _refreshMockWaterIfNeeded(SharedPreferences prefs) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastRefresh = prefs.getString('care_last_refresh') ?? '';

    if (lastRefresh != todayStr) {
      for (final contact in _contacts) {
        contact.refreshMockWater();
      }
      prefs.setString('care_last_refresh', todayStr);
      _saveContacts(prefs);
    }
  }

  /// 添加联系人
  Future<void> addContact(CareContact contact) async {
    contact.refreshMockWater();
    _contacts.add(contact);
    final prefs = await SharedPreferences.getInstance();
    await _saveContacts(prefs);
    notifyListeners();
  }

  /// 删除联系人
  Future<void> removeContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    final prefs = await SharedPreferences.getInstance();
    await _saveContacts(prefs);
    notifyListeners();
  }

  /// 发送关怀（触发本地通知 + 存 CareRecord）
  Future<void> sendCare({
    required String message,
    required List<CareContact> recipients,
  }) async {
    final now = DateTime.now();

    for (final contact in recipients) {
      final record = CareRecord(
        id: 'care_${now.millisecondsSinceEpoch}_${contact.id}',
        fromLabel: '你',
        toLabel: contact.name,
        message: message,
        sentAt: now,
      );
      _records.insert(0, record);

      // 触发本地通知
      try {
        await NotificationService.instance.showCareNotification(
          contactName: contact.name,
          message: message,
        );
      } catch (e) {
        debugPrint('Failed to send care notification: $e');
      }
    }

    // 只保留近 30 天的记录
    final cutoff = now.subtract(const Duration(days: 30));
    _records.removeWhere((r) => r.sentAt.isBefore(cutoff));

    final prefs = await SharedPreferences.getInstance();
    await _saveRecords(prefs);
    notifyListeners();
  }

  /// 模拟收到回复（本地 mock）
  Future<void> mockReply(String recordId, String replyText) async {
    final index = _records.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      final old = _records[index];
      _records[index] = CareRecord(
        id: old.id,
        fromLabel: old.fromLabel,
        toLabel: old.toLabel,
        message: old.message,
        sentAt: old.sentAt,
        isReplied: true,
        replyText: replyText,
      );
      final prefs = await SharedPreferences.getInstance();
      await _saveRecords(prefs);
      notifyListeners();
    }
  }

  Future<void> _saveContacts(SharedPreferences prefs) async {
    await prefs.setString(
      'care_contacts',
      jsonEncode(_contacts.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> _saveRecords(SharedPreferences prefs) async {
    await prefs.setString(
      'care_records',
      jsonEncode(_records.map((e) => e.toMap()).toList()),
    );
  }
}
