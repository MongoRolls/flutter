import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/backend_api_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/care_contact.dart';
import '../models/care_record.dart';

/// 心连心模块的状态管理
class HeartProvider extends ChangeNotifier {
  List<CareContact> _contacts = [];
  List<CareRecord> _records = [];

  List<CareContact> get contacts => List.unmodifiable(_contacts);
  List<CareRecord> get records => List.unmodifiable(_records);

  /// 是否已发送过关怀
  bool get hasSentCare => _records.any((r) => r.fromLabel == '你');

  /// 初始化加载（无预置 mock；首次为空列表）
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final contactsJson = prefs.getString('care_contacts');
      var localContacts = <CareContact>[];
      final localById = <String, CareContact>{};
      if (contactsJson != null) {
        final list = jsonDecode(contactsJson) as List;
        localContacts = list.map((e) => CareContact.fromMap(e)).toList();
        for (final c in localContacts) {
          localById[c.id] = c;
        }
      }

      var loadedFromRemote = false;
      final backend = BackendApiService.instance;
      if (backend.isAuthenticated) {
        try {
          final list = await backend.getCareContacts();
          _contacts = list
              .map((e) {
                final contact = e['contact'] as Map<String, dynamic>?;
                final contactId =
                    (e['contactId'] as String?) ??
                    (contact?['id'] as String?) ??
                    '';
                if (contactId.isEmpty) return null;
                final remoteName =
                    (e['nickname'] as String?) ??
                    (contact?['nickname'] as String?) ??
                    '水友';
                final local = localById[contactId];
                return CareContact(
                  id: contactId,
                  name: remoteName,
                  relationship: local?.relationship ?? 'friend',
                  avatarEmoji: local?.avatarEmoji ?? '😊',
                  mockDailyGoalMl: local?.mockDailyGoalMl ?? 2000,
                  mockTodayMl: local?.mockTodayMl ?? 0,
                );
              })
              .whereType<CareContact>()
              .toList();
          await _saveContacts(prefs);
          loadedFromRemote = true;
        } catch (e) {
          debugPrint('Error loading contacts from server: $e');
          _contacts = List.of(localContacts);
        }
      }

      if (!loadedFromRemote) {
        _contacts = List.of(localContacts);
      }

      final recordsJson = prefs.getString('care_records');
      if (recordsJson != null) {
        final list = jsonDecode(recordsJson) as List;
        _records = list.map((e) => CareRecord.fromMap(e)).toList();
      } else {
        _records = [];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading heart data: $e');
    }
  }

  /// 添加联系人
  Future<void> addContact(CareContact contact) async {
    final idx = _contacts.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) {
      _contacts[idx] = contact;
    } else {
      _contacts.add(contact);
    }
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

      try {
        await NotificationService.instance.showCareNotification(
          contactName: contact.name,
          message: message,
        );
      } catch (e) {
        debugPrint('Failed to send care notification: $e');
      }
    }

    final cutoff = now.subtract(const Duration(days: 30));
    _records.removeWhere((r) => r.sentAt.isBefore(cutoff));

    final prefs = await SharedPreferences.getInstance();
    await _saveRecords(prefs);
    notifyListeners();
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
