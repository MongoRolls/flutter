import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/drink_log.dart';
import '../models/drink_preset.dart';
import '../models/user_profile.dart';
import '../models/weather_data.dart';
import '../services/backend_api_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../utils/goal_predictor.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile();
  int _todayMl = 0;
  final List<DrinkLog> _logs = [];
  String _todayDate = '';
  // 本月打卡记录：day -> totalMl
  final Map<int, int> _monthlyHits = {};
  int _streakDays = 0;
  WeatherData? _weatherData;
  GoalPrediction? _goalPrediction;
  int? _dynamicGoalMl;
  List<DrinkPreset> _drinkPresets = List.of(DrinkPreset.defaults);

  UserProfile get profile => _profile;
  int get todayMl => _todayMl;
  List<DrinkLog> get logs => List.unmodifiable(_logs);
  double get progress => _profile.dailyGoalMl > 0
      ? (_todayMl / _profile.dailyGoalMl).clamp(0.0, 1.0)
      : 0.0;
  int get remainingMl =>
      (_profile.dailyGoalMl - _todayMl).clamp(0, _profile.dailyGoalMl);
  Map<int, int> get monthlyHits => Map.unmodifiable(_monthlyHits);
  int get streakDays => _streakDays;
  WeatherData? get weatherData => _weatherData;
  GoalPrediction? get goalPrediction => _goalPrediction;
  int? get dynamicGoalMl => _dynamicGoalMl;
  List<DrinkPreset> get drinkPresets => List.unmodifiable(_drinkPresets);

  String get _currentDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_profile');
    if (data != null) {
      _profile = UserProfile.fromMap(jsonDecode(data));
    }

    // 检查日期，跨天则清零
    final savedDate = prefs.getString('today_date') ?? '';
    final today = _currentDate;
    if (savedDate == today) {
      _todayMl = prefs.getInt('today_ml') ?? 0;
      final logsJson = prefs.getString('today_logs');
      if (logsJson != null) {
        final list = jsonDecode(logsJson) as List;
        _logs.clear();
        _logs.addAll(list.map((e) => DrinkLog.fromMap(e)));
      }
    } else {
      // 新的一天，先从 prefs 读取昨天的实际数据再归档，然后清零
      final prevMl = prefs.getInt('today_ml') ?? 0;
      if (savedDate.isNotEmpty && prevMl > 0) {
        await _archiveDayData(savedDate, prevMl);
      }
      _todayMl = 0;
      _logs.clear();
      await prefs.setString('today_date', today);
      await prefs.setInt('today_ml', 0);
      await prefs.setString('today_logs', '[]');
    }
    _todayDate = today;

    // 加载自定义杯子预设
    _loadDrinkPresets(prefs);

    // 加载月度打卡和连续天数
    _loadMonthlyHits(prefs);
    _computeStreak(prefs);

    // 异步加载天气和动态目标（不阻塞主流程）
    _loadWeatherAndGoal();

    notifyListeners();
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(_profile.toMap()));
    notifyListeners();
    // 异步同步到后端（不阻塞 UI）
    final backend = BackendApiService.instance;
    if (backend.isAuthenticated) {
      () async {
        try {
          await backend.updateProfile(_profile.toMap());
        } catch (e) {
          debugPrint('Profile sync failed: $e');
        }
      }();
    }
  }

  void updateProfile(UserProfile newProfile) {
    _profile = newProfile;
    saveProfile();
  }

  // ── 杯子预设管理 ──

  void _loadDrinkPresets(SharedPreferences prefs) {
    final json = prefs.getString('drink_presets');
    if (json != null) {
      final list = jsonDecode(json) as List;
      _drinkPresets = list.map((e) => DrinkPreset.fromMap(e)).toList();
    }
  }

  Future<void> _saveDrinkPresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'drink_presets',
      jsonEncode(_drinkPresets.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> addDrinkPreset(DrinkPreset preset) async {
    _drinkPresets.add(preset);
    await _saveDrinkPresets();
    notifyListeners();
  }

  Future<void> removeDrinkPreset(int index) async {
    if (index >= 0 && index < _drinkPresets.length) {
      _drinkPresets.removeAt(index);
      await _saveDrinkPresets();
      notifyListeners();
    }
  }

  Future<void> updateDrinkPreset(int index, DrinkPreset preset) async {
    if (index >= 0 && index < _drinkPresets.length) {
      _drinkPresets[index] = preset;
      await _saveDrinkPresets();
      notifyListeners();
    }
  }

  Future<void> resetDrinkPresets() async {
    _drinkPresets = List.of(DrinkPreset.defaults);
    await _saveDrinkPresets();
    notifyListeners();
  }

  Future<void> addDrink(
    int ml, {
    String type = '💧',
    String desc = '喝水',
  }) async {
    // 检查是否跨天
    final today = _currentDate;
    if (_todayDate != today) {
      if (_todayDate.isNotEmpty && _todayMl > 0) {
        final prefs = await SharedPreferences.getInstance();
        await _archiveDayData(_todayDate, _todayMl);
        _loadMonthlyHits(prefs);
        _computeStreak(prefs);
      }
      _todayMl = 0;
      _logs.clear();
      _todayDate = today;
    }

    _todayMl = (_todayMl + ml).clamp(0, 9999);
    final now = DateTime.now();
    _logs.add(
      DrinkLog(
        time:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        icon: type,
        description: desc,
        ml: ml,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('today_date', today);
    await prefs.setInt('today_ml', _todayMl);
    await prefs.setString(
      'today_logs',
      jsonEncode(_logs.map((e) => e.toMap()).toList()),
    );

    // 更新月度打卡数据
    final day = now.day;
    _monthlyHits[day] = _todayMl;
    await _saveMonthlyHits(prefs);
    _computeStreak(prefs);

    // 异步同步到后端（不阻塞 UI）
    final backend = BackendApiService.instance;
    if (backend.isAuthenticated) {
      () async {
        try {
          await backend.createDrinkLog(
            ml: ml,
            icon: type,
            description: desc,
            loggedAt: now,
          );
        } catch (e) {
          debugPrint('DrinkLog sync failed: $e');
        }
      }();
    }

    notifyListeners();
  }

  Future<void> _archiveDayData(String dateStr, int totalMl) async {
    final prefs = await SharedPreferences.getInstance();
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final now = DateTime.now();
      // 只保存本月的数据到 monthlyHits
      if (year == now.year && month == now.month) {
        _monthlyHits[day] = totalMl;
        await _saveMonthlyHits(prefs);
      }
      // 保存到历史记录中（用于计算连续天数）
      final historyKey = 'history_$dateStr';
      await prefs.setInt(historyKey, totalMl);
    }
  }

  void _loadMonthlyHits(SharedPreferences prefs) {
    _monthlyHits.clear();
    final now = DateTime.now();
    final key = 'monthly_hits_${now.year}_${now.month}';
    final data = prefs.getString(key);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      for (final entry in map.entries) {
        _monthlyHits[int.parse(entry.key)] = entry.value as int;
      }
    }
    // 加入今天的数据
    if (_todayMl > 0) {
      _monthlyHits[now.day] = _todayMl;
    }
  }

  Future<void> _saveMonthlyHits(SharedPreferences prefs) async {
    final now = DateTime.now();
    final key = 'monthly_hits_${now.year}_${now.month}';
    final map = _monthlyHits.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(key, jsonEncode(map));
  }

  void _computeStreak(SharedPreferences prefs) {
    _streakDays = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);

    // 如果今天还没达标，从昨天开始算
    if (_todayMl < _profile.dailyGoalMl) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    for (var i = 0; i < 365; i++) {
      final dateStr =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      final ml = prefs.getInt('history_$dateStr') ?? 0;

      // 也检查月度缓存
      if (checkDate.year == now.year && checkDate.month == now.month) {
        final dayMl = _monthlyHits[checkDate.day] ?? ml;
        if (dayMl >= _profile.dailyGoalMl) {
          _streakDays++;
        } else {
          break;
        }
      } else if (ml >= _profile.dailyGoalMl) {
        _streakDays++;
      } else {
        break;
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // 如果今天已达标，加上今天
    if (_todayMl >= _profile.dailyGoalMl && _streakDays == 0) {
      _streakDays = 1;
    }
  }

  Future<void> _loadWeatherAndGoal() async {
    try {
      final location = await LocationService.instance.getCurrentLocation();

      // 缓存位置坐标
      if (!location.isDefault) {
        _profile.cachedLat = location.lat;
        _profile.cachedLon = location.lon;
        saveProfile();
      }

      _weatherData = await WeatherService.instance.getWeather(
        location.lat,
        location.lon,
      );

      _goalPrediction = GoalPredictor.predict(
        weightKg: _profile.weight,
        activityLevel: _profile.activityLevel,
        weather: _weatherData,
      );
      _dynamicGoalMl = _goalPrediction!.predictedMl;

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load weather/goal: $e');
      _dynamicGoalMl = _profile.dailyGoalMl;
      notifyListeners();
    }
  }

  /// 用户一键采纳 AI 建议目标
  void adoptDynamicGoal() {
    if (_dynamicGoalMl != null && _dynamicGoalMl != _profile.dailyGoalMl) {
      _profile.dailyGoalMl = _dynamicGoalMl!;
      saveProfile();
      notifyListeners();
    }
  }

  /// 手动刷新天气和动态目标
  Future<void> refreshWeather() async {
    await _loadWeatherAndGoal();
  }
}
