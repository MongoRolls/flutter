import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/backend_api_service.dart';
import '../models/care_contact.dart';

/// 队友列表：与后端 `CareContact` 同步（好友短码添加）
class HeartProvider extends ChangeNotifier {
  List<CareContact> _contacts = [];

  List<CareContact> get contacts => List.unmodifiable(_contacts);

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
          final remoteContacts = list
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
                final rowId = e['id'] as String?;
                return CareContact(
                  id: contactId,
                  name: remoteName,
                  serverRowId: rowId ?? local?.serverRowId,
                  relationship: local?.relationship ?? 'friend',
                  avatarEmoji: local?.avatarEmoji ?? '😊',
                  mockDailyGoalMl: local?.mockDailyGoalMl ?? 2000,
                  mockTodayMl: local?.mockTodayMl ?? 0,
                );
              })
              .whereType<CareContact>()
              .toList();
          _contacts = remoteContacts;
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

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading heart data: $e');
    }
  }

  /// 添加联系人（已登录时同步创建后端记录）
  Future<void> addContact(CareContact contact) async {
    final backend = BackendApiService.instance;
    var toStore = contact;
    if (backend.isAuthenticated) {
      final r = await backend.createCareContact(
        contactId: contact.id,
        nickname: contact.name,
      );
      final rowId = r['id'] as String?;
      toStore = CareContact(
        id: contact.id,
        name: contact.name,
        serverRowId: rowId ?? contact.serverRowId,
        relationship: contact.relationship,
        avatarEmoji: contact.avatarEmoji,
        mockDailyGoalMl: contact.mockDailyGoalMl,
        mockTodayMl: contact.mockTodayMl,
      );
    }
    final idx = _contacts.indexWhere((c) => c.id == toStore.id);
    if (idx >= 0) {
      _contacts[idx] = toStore;
    } else {
      _contacts.add(toStore);
    }
    final prefs = await SharedPreferences.getInstance();
    await _saveContacts(prefs);
    notifyListeners();
  }

  /// 删除队友（已登录且存在 [CareContact.serverRowId] 时同步调用后端删除）
  Future<void> removeContact(String id) async {
    final idx = _contacts.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final removed = _contacts[idx];
    final backend = BackendApiService.instance;
    if (backend.isAuthenticated && removed.serverRowId != null) {
      await backend.deleteCareContact(removed.serverRowId!);
    }
    _contacts.removeAt(idx);
    final prefs = await SharedPreferences.getInstance();
    await _saveContacts(prefs);
    notifyListeners();
  }

  Future<void> _saveContacts(SharedPreferences prefs) async {
    await prefs.setString(
      'care_contacts',
      jsonEncode(_contacts.map((e) => e.toMap()).toList()),
    );
  }
}
