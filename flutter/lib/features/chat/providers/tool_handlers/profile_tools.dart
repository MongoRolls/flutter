import 'dart:convert';

import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/user_provider.dart';
import '../../services/function_registry.dart';

List<FunctionDefinition> createProfileTools(UserProvider userProvider) {
  return [
    FunctionDefinition(
      name: 'get_user_profile',
      description: '查询用户基本信息和健康数据',
      parameters: {'type': 'object', 'properties': {}},
      handler: (args) async {
        final p = userProvider.profile;
        return jsonEncode({
          'nickname': p.nickname.isEmpty ? '用户' : p.nickname,
          'gender': p.gender,
          'weight_kg': p.weight,
          'activity_level': p.activityLevel,
          'daily_goal_ml': p.dailyGoalMl,
          'recommended_goal_ml': p.recommendedGoal,
          'wake_time': p.wakeTime,
          'bed_time': p.bedTime,
          'reminder_interval_min': p.reminderIntervalMin,
          'streak_days': userProvider.streakDays,
        });
      },
    ),
    FunctionDefinition(
      name: 'update_daily_goal',
      description: '调整用户每日饮水目标',
      parameters: {
        'type': 'object',
        'properties': {
          'goal_ml': {
            'type': 'integer',
            'description': '新的每日饮水目标，单位毫升',
          },
        },
        'required': ['goal_ml'],
      },
      handler: (args) async {
        final goalMl = (args['goal_ml'] as num?)?.toInt() ?? 2000;
        final clamped = goalMl.clamp(500, 5000);
        final p = userProvider.profile;
        final newProfile = UserProfile(
          nickname: p.nickname,
          gender: p.gender,
          activityLevel: p.activityLevel,
          weight: p.weight,
          dailyGoalMl: clamped,
          wakeTime: p.wakeTime,
          bedTime: p.bedTime,
          reminderIntervalMin: p.reminderIntervalMin,
          reminderStyle: p.reminderStyle,
          notificationsEnabled: p.notificationsEnabled,
          onboardingCompleted: p.onboardingCompleted,
          cachedLat: p.cachedLat,
          cachedLon: p.cachedLon,
        );
        userProvider.updateProfile(newProfile);
        return jsonEncode({
          'success': true,
          'new_goal_ml': clamped,
          'message': '每日饮水目标已更新为 ${clamped}ml',
        });
      },
    ),
  ];
}
