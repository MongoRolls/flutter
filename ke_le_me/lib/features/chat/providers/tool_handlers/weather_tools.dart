import 'dart:convert';

import '../../../../core/providers/user_provider.dart';
import '../../services/function_registry.dart';

List<FunctionDefinition> createWeatherTools(UserProvider userProvider) {
  return [
    FunctionDefinition(
      name: 'get_weather',
      description: '获取用户当前位置的天气数据',
      parameters: {'type': 'object', 'properties': {}},
      handler: (args) async {
        final weather = userProvider.weatherData;
        if (weather == null) {
          return jsonEncode({'error': '天气数据暂不可用'});
        }
        return jsonEncode({
          'temperature': weather.temperature,
          'apparent_temperature': weather.apparentTemp,
          'humidity': weather.humidity,
          'uv_index': weather.uvIndexMax,
          'weather': weather.weatherDescription,
          'temp_max': weather.tempMax,
          'temp_min': weather.tempMin,
        });
      },
    ),
    FunctionDefinition(
      name: 'get_daily_recommendation',
      description: '获取 AI 基于天气和用户信息计算的每日饮水推荐量（只读）',
      parameters: {'type': 'object', 'properties': {}},
      handler: (args) async {
        final prediction = userProvider.goalPrediction;
        final dynamicGoal = userProvider.dynamicGoalMl;
        return jsonEncode({
          'current_goal_ml': userProvider.profile.dailyGoalMl,
          'recommended_ml': dynamicGoal ?? userProvider.profile.dailyGoalMl,
          'factors': prediction?.factors ?? {},
          'explanation': prediction?.explanation ?? '基于体重的标准推荐',
        });
      },
    ),
  ];
}
