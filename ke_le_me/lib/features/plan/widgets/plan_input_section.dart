import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../common/widgets/glass_card.dart';
import '../providers/plan_provider.dart';
import 'weather_status_widget.dart';

class PlanInputSection extends StatefulWidget {
  final PlanProvider planProvider;
  final String wakeTime;
  final VoidCallback? onWakeTimeTap;

  const PlanInputSection({
    super.key,
    required this.planProvider,
    required this.wakeTime,
    this.onWakeTimeTap,
  });

  @override
  State<PlanInputSection> createState() => _PlanInputSectionState();
}

class _PlanInputSectionState extends State<PlanInputSection> {
  late final TextEditingController _noteController;

  PlanProvider get _p => widget.planProvider;

  static const _activityTypes = ['久坐', '步行', '中等运动', '高强度运动'];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: _p.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: _p.isInputExpanded
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: _buildExpanded(),
      secondChild: _buildCollapsed(),
    );
  }

  Widget _buildCollapsed() {
    return GlassCard(
      child: GestureDetector(
        onTap: () => _p.setInputExpanded(true),
        child: const Row(
          children: [
            Icon(Icons.tune, size: 16, color: AppColors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '修改计划参数',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '今日计划参数',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_p.todayPlan != null)
                GestureDetector(
                  onTap: () => _p.setInputExpanded(false),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            '今日主要活动',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildActivitySelector(),
          const SizedBox(height: 16),

          const Text(
            '天气',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          WeatherStatusWidget(planProvider: _p),
          const SizedBox(height: 16),

          const Text(
            '起床时间',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildWakeTimeRow(),
          const SizedBox(height: 16),

          const Text(
            '今日备注',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLength: 100,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '例如：今天有篮球比赛、感冒了多喝水...',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
              filled: true,
              fillColor: AppColors.bgSection,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              counterStyle: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
            onChanged: (v) => _p.note = v,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _activityTypes.map((type) {
        final isSelected = _p.activityType == type;
        return GestureDetector(
          onTap: () => _p.setActivityType(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.blue : AppColors.bgSection,
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: AppColors.divider),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWakeTimeRow() {
    return GestureDetector(
      onTap: widget.onWakeTimeTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSection,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: AppColors.blue),
            const SizedBox(width: 8),
            Text(
              widget.wakeTime,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.edit_outlined,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
