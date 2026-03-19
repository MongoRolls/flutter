import '../models/weather_data.dart';

class GoalPrediction {
  final int predictedMl;
  final Map<String, double> factors;
  final String explanation;

  const GoalPrediction({
    required this.predictedMl,
    required this.factors,
    required this.explanation,
  });
}

class GoalPredictor {
  const GoalPredictor._();

  static GoalPrediction predict({
    required double weightKg,
    required String activityLevel,
    required WeatherData? weather,
  }) {
    double base = weightKg * 35;
    final factors = <String, double>{};

    if (weather != null) {
      if (weather.temperature > 35) {
        base *= 1.25;
        factors['高温(>35°C)'] = 0.25;
      } else if (weather.temperature > 30) {
        base *= 1.15;
        factors['炎热(>30°C)'] = 0.15;
      } else if (weather.temperature > 25) {
        base *= 1.05;
        factors['温暖(>25°C)'] = 0.05;
      }

      if (weather.humidity < 30) {
        base *= 1.10;
        factors['干燥(<30%)'] = 0.10;
      }

      if (weather.uvIndexMax > 8) {
        base *= 1.10;
        factors['强紫外线(UV>8)'] = 0.10;
      } else if (weather.uvIndexMax > 5) {
        base *= 1.05;
        factors['中等紫外线(UV>5)'] = 0.05;
      }
    }

    switch (activityLevel) {
      case '中等':
        base *= 1.15;
        factors['中等运动'] = 0.15;
      case '较多':
        base *= 1.25;
        factors['大量运动'] = 0.25;
    }

    final predicted = base.round().clamp(1500, 5000);
    return GoalPrediction(
      predictedMl: predicted,
      factors: factors,
      explanation: _buildExplanation(predicted, factors),
    );
  }

  static String _buildExplanation(int predicted, Map<String, double> factors) {
    if (factors.isEmpty) return '基于体重的标准推荐';
    final parts = factors.entries
        .map((e) => '${e.key} +${(e.value * 100).round()}%')
        .join('，');
    return parts;
  }
}
