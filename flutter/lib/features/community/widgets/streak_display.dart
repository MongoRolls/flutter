import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 连续打卡展示（火焰 + 周日历）
class StreakDisplay extends StatefulWidget {
  final int streakDays;
  final int todayMl;
  final int dailyGoalMl;
  final Map<int, int> monthlyHits;

  const StreakDisplay({
    super.key,
    required this.streakDays,
    required this.todayMl,
    required this.dailyGoalMl,
    required this.monthlyHits,
  });

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // 今天未达标时轻微抖动
    if (widget.todayMl < widget.dailyGoalMl) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreakDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.todayMl >= widget.dailyGoalMl) {
      _shakeController.stop();
    } else if (!_shakeController.isAnimating) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  bool get _todayDone => widget.todayMl >= widget.dailyGoalMl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 火焰 + 连续天数
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _shakeController,
              builder: (_, child) {
                final offset = _todayDone
                    ? 0.0
                    : (_shakeController.value - 0.5) * 4;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Text(
                '🔥',
                style: TextStyle(
                  fontSize: 40,
                  color: _todayDone ? null : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '连续 ${widget.streakDays} 天',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _todayDone ? AppColors.orangeFire : AppColors.grey,
                  ),
                ),
                Text(
                  _todayDone ? '太棒了，继续保持！' : '今天还没达标，加油！',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 本周 7 格日历
        _buildWeekCalendar(),
      ],
    );
  }

  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Monday, 7=Sunday
    final monday = now.subtract(Duration(days: weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final date = monday.add(Duration(days: i));
        final isToday =
            date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
        final dayMl = (date.year == now.year && date.month == now.month)
            ? (widget.monthlyHits[date.day] ?? 0)
            : 0;
        // 今天用当前实际值
        final actualMl = isToday ? widget.todayMl : dayMl;
        final isDone = actualMl >= widget.dailyGoalMl;
        final isFuture = date.isAfter(now);

        return Column(
          children: [
            Text(
              ['一', '二', '三', '四', '五', '六', '日'][i],
              style: TextStyle(
                fontSize: 11,
                color: isToday ? AppColors.blue : AppColors.textHint,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFuture
                    ? Colors.transparent
                    : isDone
                    ? AppColors.blue
                    : Colors.transparent,
                border: Border.all(
                  color: isToday
                      ? AppColors.blue
                      : isFuture
                      ? AppColors.greyLight
                      : isDone
                      ? AppColors.blue
                      : AppColors.greyLight,
                  width: isToday ? 2 : 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Text('💧', style: TextStyle(fontSize: 14))
                  : Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isToday ? AppColors.blue : AppColors.grey,
                        fontWeight: isToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
