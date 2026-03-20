import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../core/providers/user_provider.dart';
import '../providers/plan_provider.dart';
import '../models/today_plan.dart';
import 'action_row.dart';
import 'slot_timeline.dart';

class AiPlanResultSection extends StatelessWidget {
  final PlanProvider planProvider;
  final UserProvider userProvider;

  const AiPlanResultSection({
    super.key,
    required this.planProvider,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    final plan = planProvider.todayPlan;
    if (plan == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(context, plan),
        ActionRow(planProvider: planProvider),
        const SizedBox(height: 4),
        SlotTimeline(
          planProvider: planProvider,
          plan: plan,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, TodayPlan plan) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'AI 建议',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  planProvider.reset();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bgSection,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.summary,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                '建议总量 ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              Text(
                '${plan.totalMl}ml',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
              const Spacer(),
              if (plan.cityName != null)
                Text(
                  '📍 ${plan.cityName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
