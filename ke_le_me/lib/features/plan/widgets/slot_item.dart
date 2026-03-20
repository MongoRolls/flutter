import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/today_plan.dart';

class SlotItem extends StatefulWidget {
  final PlanTimeSlot slot;
  final bool isCompleted;
  final bool isLast;
  final VoidCallback onTap;

  const SlotItem({
    super.key,
    required this.slot,
    required this.isCompleted,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<SlotItem> createState() => _SlotItemState();
}

class _SlotItemState extends State<SlotItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(SlotItem old) {
    super.didUpdateWidget(old);
    if (old.isCompleted != widget.isCompleted ||
        old.slot.time != widget.slot.time) {
      _updatePulse();
    }
  }

  void _updatePulse() {
    final now = DateTime.now();
    final parts = widget.slot.time.split(':');
    final dt = DateTime(
      now.year, now.month, now.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );
    final mins = dt.difference(now).inMinutes;
    if (!widget.isCompleted && mins >= 0 && mins <= 30) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final parts = widget.slot.time.split(':');
    final slotTime = DateTime(
      now.year, now.month, now.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );
    final isPast = now.isAfter(slotTime);
    final isUpcoming = !isPast && slotTime.difference(now).inMinutes <= 30;

    final dotColor = widget.isCompleted
        ? AppColors.green
        : isUpcoming
            ? AppColors.blue
            : isPast
                ? AppColors.textHint
                : AppColors.divider;

    final rowOpacity = (isPast && !widget.isCompleted) ? 0.5 : 1.0;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: rowOpacity,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: widget.isCompleted
                              ? AppColors.green
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: dotColor, width: 2),
                        ),
                        child: widget.isCompleted
                            ? const Icon(Icons.check, size: 8, color: Colors.white)
                            : null,
                      ),
                      if (!widget.isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: widget.isCompleted
                                ? AppColors.green.withValues(alpha: 0.3)
                                : AppColors.divider,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isCompleted
                          ? AppColors.greenLight
                          : isUpcoming
                              ? AppColors.blueLight
                              : AppColors.bgSection,
                      borderRadius: BorderRadius.circular(10),
                      border: isUpcoming && !widget.isCompleted
                          ? Border.all(
                              color: AppColors.blue.withValues(
                                alpha: 0.2 + _pulse.value * 0.5,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isCompleted
                                ? AppColors.green.withValues(alpha: 0.15)
                                : AppColors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.slot.time,
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.isCompleted
                                  ? AppColors.green
                                  : AppColors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.slot.note,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${widget.slot.ml}ml',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.isCompleted
                                ? AppColors.green
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
