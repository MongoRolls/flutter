import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_provider.dart';
import '../providers/plan_provider.dart';
import '../widgets/basic_goal_card.dart';
import '../widgets/plan_input_section.dart';
import '../widgets/streaming_text_card.dart';
import '../widgets/ai_plan_result_section.dart';

class PlanScreen extends StatefulWidget {
  final UserProvider userProvider;
  final PlanProvider planProvider;

  const PlanScreen({
    super.key,
    required this.userProvider,
    required this.planProvider,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  PlanProvider get _p => widget.planProvider;
  UserProvider get _u => widget.userProvider;

  @override
  void initState() {
    super.initState();
    _p.addListener(_onPlanChanged);
  }

  @override
  void dispose() {
    _p.removeListener(_onPlanChanged);
    super.dispose();
  }

  void _onPlanChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BasicGoalCard(userProvider: _u),
                    PlanInputSection(
                      planProvider: _p,
                      wakeTime: _p.wakeTimeOverride.isEmpty
                          ? _u.profile.wakeTime
                          : _p.wakeTimeOverride,
                      onWakeTimeTap: _showWakeTimePicker,
                    ),
                    _buildGenerateButton(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: switch (_p.status) {
                        PlanStatus.generating => StreamingTextCard(
                            key: const ValueKey('streaming'),
                            text: _p.streamingText,
                          ),
                        PlanStatus.hasPlan => AiPlanResultSection(
                            key: const ValueKey('result'),
                            planProvider: _p,
                            userProvider: _u,
                          ),
                        _ => const SizedBox.shrink(key: ValueKey('none')),
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今日安排',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${now.year}年${now.month}月${now.day}日',
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

  Widget _buildGenerateButton() {
    final status = _p.status;

    if (status == PlanStatus.loadingPlan ||
        status == PlanStatus.loadingWeather) {
      return _buildSpinnerButton('准备中...');
    }

    if (status == PlanStatus.generating) {
      return _buildSpinnerButton('AI 生成中...');
    }

    if (status == PlanStatus.parseError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _p.errorMessage ?? '生成失败',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _p.generatePlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('重试'),
              ),
            ),
          ],
        ),
      );
    }

    if (status == PlanStatus.inputReady || status == PlanStatus.weatherError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: status == PlanStatus.inputReady ? _p.generatePlan : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🤖 ', style: TextStyle(fontSize: 16)),
                Text(
                  'AI 生成今日计划',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSpinnerButton(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  void _showWakeTimePicker() async {
    final current = _p.wakeTimeOverride.isEmpty
        ? _u.profile.wakeTime
        : _p.wakeTimeOverride;
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null) {
      _p.setWakeTimeOverride(
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }
}
