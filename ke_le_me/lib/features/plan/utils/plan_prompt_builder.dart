import '../../../core/models/weather_data.dart';
import '../../../core/providers/user_provider.dart';

/// 构建 Plan 生成的 System Prompt 和 User Prompt
class PlanPromptBuilder {
  const PlanPromptBuilder._();

  /// System Prompt：要求 AI 只返回纯 JSON
  static const String systemPrompt = '''
你是一个专业饮水健康顾问。用户会提供个人信息和当天情况，你必须返回一个**纯 JSON 对象**，
不得包含任何其他文字、markdown 代码块标记或解释。

返回格式：
{
  "summary": "string（50-100字，中文，说明今日建议和关键理由）",
  "totalMl": number（整百，范围 1500-5000）,
  "slots": [
    { "time": "HH:mm", "ml": number（50的倍数）, "note": "string（10-20字）" }
  ]
}

要求：
- slots 按时间升序排列
- slots 数量 8-12 个
- 所有 slot ml 之和必须等于 totalMl
- 时间范围：起床时间 到 睡前 30 分钟
- note 简洁有针对性（结合活动和天气，不要泛泛而谈）''';

  /// User Prompt：组合用户信息 + 当日情况
  static String build({
    required UserProvider userProvider,
    required WeatherData? weather,
    required String? cityName,
    required String activityType,
    required String note,
    required String wakeTime,
  }) {
    final profile = userProvider.profile;
    final gender = profile.gender == 'male' ? '男' : '女';
    final now = DateTime.now();

    String weatherStr;
    if (weather != null) {
      weatherStr =
          '${cityName ?? ''}  气温 ${weather.temperature.round()}℃'
          '（体感 ${weather.apparentTemp.round()}℃）'
          '，湿度 ${weather.humidity.round()}%'
          '，UV指数 ${weather.uvIndexMax.round()}'
          '，天气 ${weather.weatherDescription}';
    } else {
      weatherStr = '天气数据不可用';
    }

    return '''
用户信息：
- 性别：$gender
- 体重：${profile.weight}kg
- 基础活动量：${profile.activityLevel}

今日情况：
- 今日主要活动：$activityType
- 起床时间：$wakeTime，睡觉时间：${profile.bedTime}
- 当前天气：$weatherStr
- 今日备注：${note.isEmpty ? '无' : note}

当前时间：${now.hour}:${now.minute.toString().padLeft(2, '0')}
今日已喝水：${userProvider.todayMl}ml

请生成今日个性化饮水计划。''';
  }
}
