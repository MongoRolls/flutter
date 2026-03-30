import 'package:flutter/material.dart';

import '../../../common/widgets/app_confirm_dialog.dart';
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

  Future<void> _confirmAdoptGoal(BuildContext context) async {
    final plan = planProvider.todayPlan;
    if (plan == null) return;

    final ok = await showAppConfirmDialog(
      context: context,
      title: '设为今日目标',
      message: '将每日饮水目标更新为 ${plan.totalMl}ml？',
      confirmLabel: '确认',
    );
    if (ok != true || !context.mounted) return;
    planProvider.adoptAsGoal();
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
  }

  Future<void> _confirmSyncReminders(
    BuildContext context,
    List<String> futureSlotTimes,
  ) async {
    final ok = await showAppConfirmDialog(
      context: context,
      title: '设置今日饮水提醒',
      message: '将为 ${futureSlotTimes.join(" / ")} 等 ${futureSlotTimes.length} 个时间点设置提醒，'
          '今日已有的计划提醒会被替换。',
      confirmLabel: '确认',
    );
    if (ok != true || !context.mounted) return;
    final scheduled = await planProvider.scheduleSlotReminders();
    if (!context.mounted) return;
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
}
