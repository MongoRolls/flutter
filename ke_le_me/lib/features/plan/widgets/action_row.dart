import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/today_plan.dart';
import '../providers/plan_provider.dart';

class ActionRow extends StatelessWidget {
  final PlanProvider planProvider;

  const ActionRow({super.key, required this.planProvider});

  static List<String> _futureSlotTimes(List<PlanTimeSlot> slots) {
    final now = DateTime.now();
    return slots
        .where((s) {
          try {
            final parts = s.time.split(':');
            final dt = DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
            return dt.isAfter(now);
          } catch (e) {
            debugPrint('Error parsing slot time "${s.time}": $e');
            return false;
          }
        })
        .map((s) => s.time)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final plan = planProvider.todayPlan;
    if (plan == null) return const SizedBox.shrink();

    final futureSlotTimes = _futureSlotTimes(plan.slots);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _confirmAdoptGoal(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                '设为今日目标 (${plan.totalMl}ml)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: futureSlotTimes.isNotEmpty
                  ? () => _confirmSyncReminders(context, futureSlotTimes)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                futureSlotTimes.isNotEmpty
                    ? '同步提醒 (${futureSlotTimes.length} 个)'
                    : '今日计划已结束',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAdoptGoal(BuildContext context) {
    final plan = planProvider.todayPlan;
    if (plan == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '设为今日目标',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '将每日饮水目标更新为 ${plan.totalMl}ml？',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              planProvider.adoptAsGoal();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✓ 已将今日目标更新为 ${plan.totalMl}ml',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  backgroundColor: AppColors.bgCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              );
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _confirmSyncReminders(
    BuildContext context,
    List<String> futureSlotTimes,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '设置今日饮水提醒',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '将为 ${futureSlotTimes.join(" / ")} 等 ${futureSlotTimes.length} 个时间点设置提醒，'
          '今日已有的计划提醒会被替换。',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final scheduled = await planProvider.scheduleSlotReminders();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✓ 已设置 $scheduled 个提醒',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    backgroundColor: AppColors.bgCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                );
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
