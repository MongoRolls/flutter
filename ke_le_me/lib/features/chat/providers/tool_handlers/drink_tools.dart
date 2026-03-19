import 'dart:convert';

import '../../../../core/providers/user_provider.dart';
import '../../services/function_registry.dart';

List<FunctionDefinition> createDrinkTools(UserProvider userProvider) {
  return [
    FunctionDefinition(
      name: 'add_drink',
      description: '帮用户记录喝水量',
      parameters: {
        'type': 'object',
        'properties': {
          'ml': {'type': 'integer', 'description': '喝水量，单位毫升'},
          'type': {
            'type': 'string',
            'description': '饮品类型图标，如 💧 水、☕ 咖啡、🍵 茶等',
          },
          'desc': {'type': 'string', 'description': '饮品描述，如 温水、咖啡、绿茶等'},
        },
        'required': ['ml'],
      },
      handler: (args) async {
        final ml = (args['ml'] as num?)?.toInt() ?? 0;
        final type = args['type'] as String? ?? '💧';
        final desc = args['desc'] as String? ?? '喝水';
        await userProvider.addDrink(ml, type: type, desc: desc);
        final pct = (userProvider.progress * 100).round();
        return jsonEncode({
          'success': true,
          'recorded_ml': ml,
          'today_total_ml': userProvider.todayMl,
          'daily_goal_ml': userProvider.profile.dailyGoalMl,
          'progress_percent': pct,
          'message': '成功记录 $desc ${ml}ml，今日共 ${userProvider.todayMl}ml（$pct%）',
        });
      },
    ),
    FunctionDefinition(
      name: 'get_today_progress',
      description: '查询今日饮水进度',
      parameters: {'type': 'object', 'properties': {}},
      handler: (args) async {
        final pct = (userProvider.progress * 100).round();
        final logs = userProvider.logs;
        return jsonEncode({
          'today_ml': userProvider.todayMl,
          'daily_goal_ml': userProvider.profile.dailyGoalMl,
          'remaining_ml': userProvider.remainingMl,
          'progress_percent': pct,
          'log_count': logs.length,
          'recent_log': logs.isNotEmpty
              ? '${logs.last.time} ${logs.last.description} ${logs.last.ml}ml'
              : '暂无记录',
          'streak_days': userProvider.streakDays,
        });
      },
    ),
  ];
}
