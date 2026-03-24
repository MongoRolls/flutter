import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/user_provider.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import 'heart_provider.dart';

/// 多喝水广场模块的状态管理
class PlazaProvider extends ChangeNotifier {
  final UserProvider userProvider;
  final HeartProvider heartProvider;

  List<Challenge> _challenges = [];
  List<Achievement> _achievements = [];

  /// 上次检查成就解锁的时间戳（避免重复弹窗）
  final List<String> _newlyUnlocked = [];

  List<Challenge> get challenges => List.unmodifiable(_challenges);
  List<Achievement> get achievements => List.unmodifiable(_achievements);

  /// 获取进行中的挑战
  List<Challenge> get joinedChallenges =>
      _challenges.where((c) => c.isJoined && !c.isCompleted).toList();

  /// 获取可发现的挑战
  List<Challenge> get discoverChallenges =>
      _challenges.where((c) => !c.isJoined).toList();

  /// 获取已解锁成就数量
  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;

  /// 获取最近新解锁的成就ID列表（用于弹窗动画）
  List<String> consumeNewlyUnlocked() {
    final list = List<String>.from(_newlyUnlocked);
    _newlyUnlocked.clear();
    return list;
  }

  PlazaProvider({required this.userProvider, required this.heartProvider});

  /// 初始化加载
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载挑战
      final challengesJson = prefs.getString('plaza_challenges');
      if (challengesJson != null) {
        final list = jsonDecode(challengesJson) as List;
        _challenges = list.map((e) => Challenge.fromMap(e)).toList();
      } else {
        _challenges = Challenge.defaults;
        await _saveChallenges(prefs);
      }

      // 加载成就
      final achievementsJson = prefs.getString('plaza_achievements');
      if (achievementsJson != null) {
        final list = jsonDecode(achievementsJson) as List;
        _achievements = list.map((e) => Achievement.fromMap(e)).toList();
      } else {
        _achievements = Achievement.defaults;
        await _saveAchievements(prefs);
      }

      // 检查自动解锁
      _checkAchievements(prefs);

      // 更新挑战进度
      _updateChallengeProgress(prefs);

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
  void _updateChallengeProgress(SharedPreferences prefs) {
    final streak = userProvider.streakDays;

    for (final challenge in _challenges) {
      if (!challenge.isJoined) continue;

      switch (challenge.id) {
        case 'buddy_plan':
          // 搭子计划：基于 streak 天数，最多 30 天
          challenge.currentProgress = streak.clamp(0, 30);
        case 'iron_man':
          // 铁人挑战：连续 7 天 100%
          challenge.currentProgress = streak.clamp(0, 7);
        case 'early_bird':
          // 早起补水：简化为 streak 前 5 天
          challenge.currentProgress = streak.clamp(0, 5);
      }

      // 完成挑战时解锁对应成就
      if (challenge.isCompleted) {
        _unlockAchievement(challenge.rewardBadgeId);
      }
    }

    _saveChallenges(prefs);
  }

  /// 检查自动解锁成就
  void _checkAchievements(SharedPreferences prefs) {
    // 💧 初心一滴：有过喝水记录
    if (userProvider.todayMl > 0 || userProvider.streakDays > 0) {
      _unlockAchievement('first_drink');
    }

    // 🔥 一周连击
    if (userProvider.streakDays >= 7) {
      _unlockAchievement('week_streak');
    }

    // 🌊 月度坚持
    if (userProvider.streakDays >= 30) {
      _unlockAchievement('month_streak');
    }

    // ❤️ 首次关怀
    if (heartProvider.hasSentCare) {
      _unlockAchievement('first_care');
    }

    _saveAchievements(prefs);
  }

  /// 解锁一个成就
  void _unlockAchievement(String achievementId) {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index != -1 && !_achievements[index].isUnlocked) {
      _achievements[index].isUnlocked = true;
      _achievements[index].unlockedAt = DateTime.now();
      _newlyUnlocked.add(achievementId);
    }
  }

  /// 刷新成就和进度（外部调用，如从社区页返回时）
  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    _checkAchievements(prefs);
    _updateChallengeProgress(prefs);
    await _saveAchievements(prefs);
    notifyListeners();
  }

  /// 预留：同步到服务器（空实现）
  Future<void> syncToServer() async {
    // TODO: 上线服务端后替换实现
    debugPrint('PlazaProvider: syncToServer() — not implemented yet');
  }

  Future<void> _saveChallenges(SharedPreferences prefs) async {
    await prefs.setString(
      'plaza_challenges',
      jsonEncode(_challenges.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> _saveAchievements(SharedPreferences prefs) async {
    await prefs.setString(
      'plaza_achievements',
      jsonEncode(_achievements.map((e) => e.toMap()).toList()),
    );
  }
}
