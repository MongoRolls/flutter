import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/services/backend_api_service.dart';
import '../models/challenge.dart';

/// 社区广场：本地连续打卡挑战 + 组队挑战（服务端）
class PlazaProvider extends ChangeNotifier {
  PlazaProvider({required this.userProvider}) {
    userProvider.addListener(_onUserDataChanged);
  }

  final UserProvider userProvider;

  List<Challenge> _localChallenges = [];
  List<Challenge> _serverChallenges = [];

  List<Challenge> get challenges => List.unmodifiable(_localChallenges);

  /// 进行中的本地打卡挑战
  List<Challenge> get joinedLocalChallenges =>
      _localChallenges.where((c) => c.isJoined && !c.isCompleted).toList();

  /// 可参与的本地打卡挑战
  List<Challenge> get discoverLocalChallenges =>
      _localChallenges.where((c) => !c.isJoined).toList();

  /// 我参与的组队挑战（服务端，与 [challenges] 本地占位挑战分离）
  List<Challenge> get teamChallenges => List.unmodifiable(_serverChallenges);

  Timer? _debounceRefresh;

  void _onUserDataChanged() {
    unawaited(_refreshLocalProgressOnly());
    _debounceRefresh?.cancel();
    _debounceRefresh = Timer(const Duration(seconds: 30), () {
      unawaited(refreshFromServer());
    });
  }

  Future<void> _refreshLocalProgressOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _updateLocalChallengeProgress(prefs);
      notifyListeners();
    } catch (e) {
      debugPrint('PlazaProvider _refreshLocalProgressOnly: $e');
    }
  }

  String _localDateString() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  /// 初始化：本地挑战 + 已登录则拉取服务端组队挑战
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final challengesJson = prefs.getString('plaza_challenges');
      if (challengesJson != null) {
        final list = jsonDecode(challengesJson) as List;
        _localChallenges = list
            .map((e) => Challenge.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        _localChallenges = List.from(Challenge.defaults);
        await _saveLocalChallenges(prefs);
      }

      await _updateLocalChallengeProgress(prefs);

      final backend = BackendApiService.instance;
      if (backend.isAuthenticated) {
        await refreshFromServer();
      } else {
        _serverChallenges = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading plaza data: $e');
    }
  }

  /// 从服务端刷新「我的组队挑战」
  Future<void> refreshFromServer() async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) {
      _serverChallenges = [];
      notifyListeners();
      return;
    }
    try {
      final data = await backend.getChallengesMine(
        localDate: _localDateString(),
        tzOffset: DateTime.now().timeZoneOffset.inMinutes,
      );
      final raw = data['items'];
      if (raw is! List) {
        _serverChallenges = [];
      } else {
        _serverChallenges = raw
            .map((e) {
              try {
                return Challenge.fromServerItem(
                  Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
                );
              } catch (err) {
                debugPrint('PlazaProvider: skip bad challenge row: $err');
                return null;
              }
            })
            .whereType<Challenge>()
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('PlazaProvider refreshFromServer: $e');
    }
  }

  /// 参与本地打卡挑战
  Future<void> joinChallenge(String challengeId) async {
    final index = _localChallenges.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      _localChallenges[index].isJoined = true;
      _localChallenges[index].currentProgress = 0;
      final prefs = await SharedPreferences.getInstance();
      await _updateLocalChallengeProgress(prefs);
      await _saveLocalChallenges(prefs);
      notifyListeners();
    }
  }

  Future<void> _updateLocalChallengeProgress(SharedPreferences prefs) async {
    final streak = userProvider.streakDays;

    for (final challenge in _localChallenges) {
      if (!challenge.isJoined) continue;

      switch (challenge.id) {
        case 'buddy_plan':
          challenge.currentProgress = streak.clamp(0, 30);
          break;
        case 'iron_man':
          challenge.currentProgress = streak.clamp(0, 7);
          break;
        case 'early_bird':
          challenge.currentProgress = streak.clamp(0, 5);
          break;
      }
    }

    await _saveLocalChallenges(prefs);
  }

  Future<void> _saveLocalChallenges(SharedPreferences prefs) async {
    await prefs.setString(
      'plaza_challenges',
      jsonEncode(_localChallenges.map((e) => e.toMap()).toList()),
    );
  }

  /// 创建组队挑战（默认 7 天；[goalType] 可为个人每日或团队累计）
  Future<void> createTeamChallenge({
    required String title,
    required int goalValue,
    int durationDays = 7,
    String goalType = 'individual_daily',
  }) async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) return;
    final start = DateTime.now();
    final end = start.add(Duration(days: durationDays));
    await backend.createChallenge(
      title: title,
      goalType: goalType,
      goalValue: goalValue,
      periodStartIso: start.toIso8601String(),
      periodEndIso: end.toIso8601String(),
    );
    await refreshFromServer();
  }

  /// 确认挑战成绩（已结束挑战）
  Future<void> ackChallengeResult(String challengeId) async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) return;
    await backend.ackChallengeResult(challengeId);
    await refreshFromServer();
  }

  /// 通过邀请码加入
  Future<void> joinByInviteCode(String code) async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) return;
    await backend.joinChallenge(code);
    await refreshFromServer();
  }

  /// 退出组队挑战
  Future<void> leaveChallenge(String challengeId) async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) return;
    await backend.leaveChallenge(challengeId);
    await refreshFromServer();
  }

  /// 本地进度刷新 + 服务端列表刷新
  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    await _updateLocalChallengeProgress(prefs);
    await refreshFromServer();
  }

  @override
  void dispose() {
    userProvider.removeListener(_onUserDataChanged);
    _debounceRefresh?.cancel();
    super.dispose();
  }
}
