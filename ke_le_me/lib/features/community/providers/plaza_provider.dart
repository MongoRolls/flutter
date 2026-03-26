import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/user_provider.dart';
import '../models/challenge.dart';

/// 多喝水广场模块的状态管理（挑战 + 连续展示；成就墙已移除）
class PlazaProvider extends ChangeNotifier {
  final UserProvider userProvider;

  List<Challenge> _challenges = [];

  List<Challenge> get challenges => List.unmodifiable(_challenges);

  /// 获取进行中的挑战
  List<Challenge> get joinedChallenges =>
      _challenges.where((c) => c.isJoined && !c.isCompleted).toList();

  /// 获取可发现的挑战
  List<Challenge> get discoverChallenges =>
      _challenges.where((c) => !c.isJoined).toList();

  PlazaProvider({required this.userProvider});

  /// 初始化加载
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final challengesJson = prefs.getString('plaza_challenges');
      if (challengesJson != null) {
        final list = jsonDecode(challengesJson) as List;
        _challenges = list.map((e) => Challenge.fromMap(e)).toList();
      } else {
        _challenges = Challenge.defaults;
        await _saveChallenges(prefs);
      }

      await _updateChallengeProgress(prefs);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading plaza data: $e');
    }
  }

  /// 参与挑战
  Future<void> joinChallenge(String challengeId) async {
    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      _challenges[index].isJoined = true;
      _challenges[index].currentProgress = 0;
      final prefs = await SharedPreferences.getInstance();
      await _saveChallenges(prefs);
      notifyListeners();
    }
  }

  /// 更新挑战进度（基于 UserProvider 的数据）
  Future<void> _updateChallengeProgress(SharedPreferences prefs) async {
    final streak = userProvider.streakDays;

    for (final challenge in _challenges) {
      if (!challenge.isJoined) continue;

      switch (challenge.id) {
        case 'buddy_plan':
          challenge.currentProgress = streak.clamp(0, 30);
        case 'iron_man':
          challenge.currentProgress = streak.clamp(0, 7);
        case 'early_bird':
          challenge.currentProgress = streak.clamp(0, 5);
      }
    }

    await _saveChallenges(prefs);
  }

  /// 刷新挑战进度（外部调用，如发送关怀后）
  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    await _updateChallengeProgress(prefs);
    notifyListeners();
  }

  /// 预留：同步到服务器（空实现）
  Future<void> syncToServer() async {
    debugPrint('PlazaProvider: syncToServer() — not implemented yet');
  }

  Future<void> _saveChallenges(SharedPreferences prefs) async {
    await prefs.setString(
      'plaza_challenges',
      jsonEncode(_challenges.map((e) => e.toMap()).toList()),
    );
  }
}
