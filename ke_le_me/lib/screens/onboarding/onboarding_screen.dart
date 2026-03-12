import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  final UserProvider userProvider;

  const OnboardingScreen({super.key, required this.userProvider});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  final _nicknameController = TextEditingController();

  String _gender = '男';
  String _activityLevel = '久坐';
  double _weight = 65;
  late int _goalMl;
  String _wakeTime = '07:00';
  String _bedTime = '23:00';
  int _reminderInterval = 90;

  @override
  void initState() {
    super.initState();
    _goalMl = (_weight * 35).round();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _enableNotificationsAndFinish() async {
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.scheduleReminders(
      wakeTime: _wakeTime,
      bedTime: _bedTime,
      intervalMin: _reminderInterval,
    );
    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final profile = UserProfile(
      nickname: _nicknameController.text.isEmpty ? '用户' : _nicknameController.text,
      gender: _gender,
      activityLevel: _activityLevel,
      weight: _weight,
      dailyGoalMl: _goalMl,
      wakeTime: _wakeTime,
      bedTime: _bedTime,
      reminderIntervalMin: _reminderInterval,
      onboardingCompleted: true,
    );
    widget.userProvider.updateProfile(profile);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive ? AppColors.blue : AppColors.divider,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: 基础信息 ──
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueLight,
                boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.2), blurRadius: 20)],
              ),
              child: Center(
                child: Text('渴',
                    style: GoogleFonts.notoSansSc(
                        fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.blue)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('欢迎使用渴了么',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Center(
            child: Text('先了解一下你，为你定制健康计划',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: 28),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('你的昵称'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nicknameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '输入昵称',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.bgSection,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.blue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                _label('性别'),
                const SizedBox(height: 8),
                _chipRow(['男', '女', '其他'], _gender, (v) => setState(() => _gender = v)),

                const SizedBox(height: 20),
                _label('每周运动量'),
                const SizedBox(height: 8),
                _chipRow(
                  ['久坐', '轻度', '中度', '高强度'],
                  _activityLevel,
                  (v) => setState(() => _activityLevel = v),
                ),

                const SizedBox(height: 20),
                _label('体重'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _weight,
                        min: 40,
                        max: 120,
                        divisions: 80,
                        onChanged: (v) => setState(() {
                          _weight = v;
                          _goalMl = (v * 35).round();
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('${_weight.round()} kg',
                          textAlign: TextAlign.right,
                          style: AppTheme.monoStyle.copyWith(fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              child: const Text('继续'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: 目标设置 ──
  Widget _buildStep2() {
    final pct = (_goalMl / 4000).clamp(0.0, 1.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text('设定每日目标', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('根据你的体重推荐 ${(_weight * 35).round()}ml',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),

          GlassCard(
            child: Column(
              children: [
                SizedBox(
                  width: 160, height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160, height: 160,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 12,
                          backgroundColor: AppColors.blueLight,
                          valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_goalMl',
                            style: AppTheme.monoStyle.copyWith(fontSize: 32),
                          ),
                          const Text('ml', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('1500', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                    Expanded(
                      child: Slider(
                        value: _goalMl.toDouble(),
                        min: 1500,
                        max: 4000,
                        divisions: 25,
                        onChanged: (v) => setState(() => _goalMl = v.round()),
                      ),
                    ),
                    const Text('4000', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '每日目标: $_goalMl ml',
                    style: AppTheme.monoStyle.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _nextStep, child: const Text('继续')),
          ),
        ],
      ),
    );
  }

  // ── Step 3: 提醒时间 ──
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text('提醒计划', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('设置作息时间和提醒频率', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('起床时间'),
                const SizedBox(height: 8),
                _timePickerButton(_wakeTime, (t) => setState(() => _wakeTime = t)),

                const SizedBox(height: 20),
                _label('就寝时间'),
                const SizedBox(height: 8),
                _timePickerButton(_bedTime, (t) => setState(() => _bedTime = t)),

                const SizedBox(height: 20),
                _label('提醒间隔'),
                const SizedBox(height: 8),
                _chipRow(
                  ['30 分钟', '1 小时', '1.5 小时', '2 小时'],
                  _intervalLabel(_reminderInterval),
                  (v) => setState(() => _reminderInterval = _intervalFromLabel(v)),
                ),
              ],
            ),
          ),

          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.blueLight, shape: BoxShape.circle),
                  child: const Center(child: Text('⏰', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('提醒预览',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        '$_wakeTime ~ $_bedTime · 每${_intervalLabel(_reminderInterval)}一次',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _nextStep, child: const Text('完成设置')),
          ),
        ],
      ),
    );
  }

  // ── Step 4: 通知权限 ──
  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blueLight,
              boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.2), blurRadius: 30)],
            ),
            child: const Center(child: Text('🔔', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 28),
          Text('开启通知', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          const Text(
            '为了在最佳时机提醒你喝水\n需要开启通知权限',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textHint, fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('到点自动推送，不错过每次补水',
                      style: TextStyle(fontSize: 12, color: AppColors.blue)),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enableNotificationsAndFinish,
              child: const Text('开启通知，开始使用'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text('稍后再说', style: TextStyle(color: AppColors.textHint)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helpers ──
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 0.5,
        ),
      );

  Widget _chipRow(List<String> options, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.blue : AppColors.bgSection,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.blue : AppColors.divider,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timePickerButton(String time, ValueChanged<String> onChanged) {
    return GestureDetector(
      onTap: () async {
        final parts = time.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.blue),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onChanged(
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSection,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Text(time, style: AppTheme.monoStyle.copyWith(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.access_time, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  String _intervalLabel(int minutes) {
    if (minutes == 30) return '30 分钟';
    if (minutes == 60) return '1 小时';
    if (minutes == 90) return '1.5 小时';
    return '2 小时';
  }

  int _intervalFromLabel(String label) {
    if (label == '30 分钟') return 30;
    if (label == '1 小时') return 60;
    if (label == '1.5 小时') return 90;
    return 120;
  }
}
