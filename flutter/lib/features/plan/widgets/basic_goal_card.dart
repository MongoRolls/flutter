import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/goal_predictor.dart';
import '../../../common/widgets/glass_card.dart';

/// 基础饮水目标卡：展示基于体重/活动量/天气的推荐目标
class BasicGoalCard extends StatelessWidget {
  final UserProvider userProvider;

  const BasicGoalCard({super.key, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final prediction =
        userProvider.goalPrediction ??
        GoalPredictor.predict(
          weightKg: userProvider.profile.weight,
          activityLevel: userProvider.profile.activityLevel,
          weather: userProvider.weatherData,
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                '基础饮水目标',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${prediction.predictedMl} ml',
              style: GoogleFonts.spaceMono(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 因子 chips
          if (prediction.factors.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: prediction.factors.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${e.key} +${(e.value * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // 提示用户去设置页修改基础目标
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请前往「设置」页面修改每日目标'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '前往设置修改',
                  style: TextStyle(fontSize: 12, color: AppColors.blue),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
