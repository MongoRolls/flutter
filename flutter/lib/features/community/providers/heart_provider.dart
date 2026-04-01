import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/backend_api_service.dart';
import '../models/care_contact.dart';

/// 队友列表：与后端 `CareContact` 同步（好友短码添加）
class HeartProvider extends ChangeNotifier {
  List<CareContact> _contacts = [];

  List<CareContact> get contacts => List.unmodifiable(_contacts);

  /// [SharedPreferences.clear] 或全量重置后调用，避免内存中仍保留旧队友列表。
  void resetLocalContacts() {
    _contacts = [];
    notifyListeners();
  }

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
                  friendPushInviteEnabled:
                      local?.friendPushInviteEnabled ?? false,
                  hydrationVisible: local?.hydrationVisible ?? true,
                );
              })
              .whereType<CareContact>()
              .toList();
          _contacts = remoteContacts;
          // 饮水摘要失败时仍应持久化联系人列表；否则重启后仍读旧 prefs，新好友会「消失」。
          final hydrationOk = await _applyPeersHydration();
          await _saveContacts(prefs);
          if (!hydrationOk && kDebugMode) {
            debugPrint(
              'HeartProvider: peers hydration 未成功合并，界面可能暂用本地缓存毫升数',
            );
          }
          loadedFromRemote = true;
        } catch (e, st) {
          debugPrint('Error loading contacts from server: $e');
          if (e is DioException) {
            debugPrint(
              '  status=${e.response?.statusCode} body=${e.response?.data}',
            );
          }
          if (kDebugMode) {
            debugPrint('$st');
          }
          _contacts = List.of(localContacts);
        }
      }

      if (!loadedFromRemote) {
        _contacts = List.of(localContacts);
      }
    } catch (e) {
      debugPrint('Error loading heart data: $e');
    } finally {
      notifyListeners();
    }
  }

  /// 拉取好友当日饮水摘要并合并到 [contacts]。
  /// 网络失败时不覆写本地缓存中的毫升数（返回 false）。
  Future<bool> refreshPeersHydration() async {
    final ok = await _applyPeersHydration();
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await _saveContacts(prefs);
    }
    notifyListeners();
    return ok;
  }

  /// 成功返回 true；未登录或无联系人时视为无需拉取，返回 true；请求异常返回 false。
  Future<bool> _applyPeersHydration() async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated || _contacts.isEmpty) return true;
    try {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final tzOffset = now.timeZoneOffset.inMinutes;
      final rows = await backend.getPeersHydration(
        date: date,
        tzOffset: tzOffset,
      );
      final byUser = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final uid = r['userId'] as String?;
        if (uid != null) byUser[uid] = r;
      }
      _contacts = _contacts.map((c) {
        final row = byUser[c.id];
        if (row == null) return c;
        // 缺省视为可见（与后端 `?? true` 一致），避免旧字段缺失时被误判为隐藏。
        final visible = row['visible'] != false;
        if (!visible) {
          return c.copyWith(
            hydrationVisible: false,
            mockTodayMl: 0,
            mockDailyGoalMl: 0,
          );
        }
        final today = (row['todayMl'] as num?)?.round() ?? 0;
        final goal = (row['dailyGoalMl'] as num?)?.round() ?? 2000;
        return c.copyWith(
          hydrationVisible: true,
          mockTodayMl: today,
          mockDailyGoalMl: goal,
        );
      }).toList();
      return true;
    } catch (e, st) {
      debugPrint('Error applying peers hydration: $e');
      if (e is DioException) {
        debugPrint(
          '  status=${e.response?.statusCode} body=${e.response?.data}',
        );
      }
      if (kDebugMode) {
        debugPrint('$st');
      }
      return false;
    }
  }

  /// 添加联系人（已登录时同步创建后端记录）
  Future<void> addContact(CareContact contact) async {
    final backend = BackendApiService.instance;
    var toStore = contact;
    if (backend.isAuthenticated) {
      // 添加队友页已 POST /contacts 时带上 serverRowId，避免重复 upsert 与多余请求
      if (contact.serverRowId != null) {
        toStore = contact;
      } else {
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
          friendPushInviteEnabled: contact.friendPushInviteEnabled,
          hydrationVisible: contact.hydrationVisible,
        );
      }
    }
    final idx = _contacts.indexWhere((c) => c.id == toStore.id);
    if (idx >= 0) {
      _contacts[idx] = toStore;
    } else {
      _contacts.add(toStore);
    }
    final prefs = await SharedPreferences.getInstance();
    await _saveContacts(prefs);
    // 合并 GET /api/care/peers/hydration，否则新加好友一直显示本地占位 0% / 0ml
    if (backend.isAuthenticated) {
      await refreshPeersHydration();
    } else {
      notifyListeners();
    }
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
