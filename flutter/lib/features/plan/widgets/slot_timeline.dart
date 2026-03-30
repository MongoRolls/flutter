import 'package:flutter/material.dart';

import '../../../common/widgets/app_modal_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../common/widgets/glass_card.dart';
import '../providers/plan_provider.dart';
import '../models/today_plan.dart';
import 'slot_item.dart';

class SlotTimeline extends StatelessWidget {
  final PlanProvider planProvider;
  final TodayPlan plan;

  const SlotTimeline({
    super.key,
    required this.planProvider,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final slots = plan.slots;
    final completed = plan.completedSlots;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Text(
                '今日时间安排',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${completed.length}/${slots.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(slots.length, (i) {
            final slot = slots[i];
            final isCompleted = completed.contains(slot.time);
            final isLast = i == slots.length - 1;

            return SlotItem(
              slot: slot,
              isCompleted: isCompleted,
              isLast: isLast,
              onTap: () => _showSlotSheet(context, slot, isCompleted),
            );
          }),
        ],
      ),
    );
  }

  void _showSlotSheet(
    BuildContext context,
    PlanTimeSlot slot,
    bool isCompleted,
  ) {
    showAppModalSheet<void>(
      context: context,
      builder: (ctx) {
        if (isCompleted) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '✓ 已记录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${slot.time} · ${slot.ml}ml · ${slot.note}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    planProvider.unlogSlot(slot.time);
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: BorderSide(
                      color: AppColors.red.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('取消标记'),
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '💧 记录 ${slot.time} 的饮水',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              slot.note,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await planProvider.logSlotDrink(slot);
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '✓ 已记录 ${slot.ml}ml',
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('记录 ${slot.ml}ml'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                '取消',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
          ],
        );
      },
    );
  }
}
