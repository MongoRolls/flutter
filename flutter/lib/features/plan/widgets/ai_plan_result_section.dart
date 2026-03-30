import 'package:flutter/material.dart';

import '../../../common/widgets/app_confirm_dialog.dart';
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
        SlotTimeline(planProvider: planProvider, plan: plan),
        const SizedBox(height: 12),
        _buildRegenerateButton(context),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              if (plan.cityName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSection,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 11,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        plan.cityName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              Text(
                '${plan.totalMl}ml',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 重新生成按钮（醒目样式）
  Widget _buildRegenerateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmRegenerate(context),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text(
          '重新生成计划',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _confirmRegenerate(BuildContext context) async {
    final ok = await showAppConfirmDialog(
      context: context,
      title: '重新生成计划',
      message: '当前计划将被清除，需要重新由 AI 生成。确定要重新生成吗？',
      cancelLabel: '取消',
      confirmLabel: '重新生成',
      confirmButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
    );
    if (ok != true || !context.mounted) return;
    planProvider.reset();
  }
}
