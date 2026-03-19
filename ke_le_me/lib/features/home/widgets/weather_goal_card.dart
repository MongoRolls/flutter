import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_provider.dart';
import '../../../common/widgets/glass_card.dart';

class WeatherGoalCard extends StatelessWidget {
  final UserProvider userProvider;

  const WeatherGoalCard({super.key, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final weather = userProvider.weatherData;
    final prediction = userProvider.goalPrediction;
    final dynamicGoal = userProvider.dynamicGoalMl;
    final currentGoal = userProvider.profile.dailyGoalMl;

    if (weather == null) {
      return _buildNoWeather();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('天气 & AI 建议'),
          const SizedBox(height: 14),
          _buildWeatherRow(weather),
          if (dynamicGoal != null && dynamicGoal != currentGoal) ...[
            const SizedBox(height: 12),
            _buildAiSuggestion(dynamicGoal, currentGoal, prediction),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherRow(dynamic weather) {
    return Row(
      children: [
        Text(
          _weatherEmoji(weather.weatherCode),
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weather.temperature.round()}°C ${weather.weatherDescription}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '体感 ${weather.apparentTemp.round()}°C · 湿度 ${weather.humidity.round()}% · UV ${weather.uvIndexMax.round()}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestion(int dynamicGoal, int currentGoal, dynamic prediction) {
    final isHigher = dynamicGoal > currentGoal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'AI 建议今日 ${dynamicGoal}ml',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                ),
              ),
              const Spacer(),
              Text(
                isHigher ? '↑' : '↓',
                style: TextStyle(
                  fontSize: 13,
                  color: isHigher ? AppColors.orange : AppColors.green,
                ),
              ),
            ],
          ),
          if (prediction != null && (prediction.explanation as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              prediction.explanation as String,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () => userProvider.adoptDynamicGoal(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('采纳建议'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWeather() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '天气数据加载中...',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }

  String _weatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 57) return '🌦️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '🌨️';
    if (code <= 82) return '⛈️';
    return '🌩️';
  }
}
