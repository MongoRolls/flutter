import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile();
  int _todayMl = 0;
  final List<DrinkLog> _logs = [];

  UserProfile get profile => _profile;
  int get todayMl => _todayMl;
  List<DrinkLog> get logs => List.unmodifiable(_logs);
  double get progress => _profile.dailyGoalMl > 0
      ? (_todayMl / _profile.dailyGoalMl).clamp(0.0, 1.0)
      : 0.0;
  int get remainingMl => (_profile.dailyGoalMl - _todayMl).clamp(0, _profile.dailyGoalMl);

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_profile');
    if (data != null) {
      _profile = UserProfile.fromMap(jsonDecode(data));
    }
    _todayMl = prefs.getInt('today_ml') ?? 0;
    final logsJson = prefs.getString('today_logs');
    if (logsJson != null) {
      final list = jsonDecode(logsJson) as List;
      _logs.clear();
      _logs.addAll(list.map((e) => DrinkLog.fromMap(e)));
    }
    notifyListeners();
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(_profile.toMap()));
    notifyListeners();
  }

  void updateProfile(UserProfile newProfile) {
    _profile = newProfile;
    saveProfile();
  }

  Future<void> addDrink(int ml, {String type = '💧', String desc = '喝水'}) async {
    _todayMl = (_todayMl + ml).clamp(0, 9999);
    final now = DateTime.now();
    _logs.add(DrinkLog(
      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      icon: type,
      description: desc,
      ml: ml,
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('today_ml', _todayMl);
    await prefs.setString('today_logs', jsonEncode(_logs.map((e) => e.toMap()).toList()));
    notifyListeners();
  }
}

class DrinkLog {
  final String time;
  final String icon;
  final String description;
  final int ml;

  DrinkLog({
    required this.time,
    required this.icon,
    required this.description,
    required this.ml,
  });

  Map<String, dynamic> toMap() => {
        'time': time,
        'icon': icon,
        'description': description,
        'ml': ml,
      };

  factory DrinkLog.fromMap(Map<String, dynamic> m) => DrinkLog(
        time: m['time'] ?? '',
        icon: m['icon'] ?? '💧',
        description: m['description'] ?? '',
        ml: m['ml'] ?? 0,
      );
}
