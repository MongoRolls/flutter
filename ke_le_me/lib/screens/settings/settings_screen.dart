import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  final UserProvider userProvider;

  const SettingsScreen({super.key, required this.userProvider});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProvider get _p => widget.userProvider;

  late double _weight;
  late int _goalMl;
  late String _reminderStyle;
  late bool _notificationsEnabled;
  late bool _exerciseReminder;
  late bool _meetingPause;
  late bool _morningPlan;
  late String _wakeTime;
  late String _bedTime;
  late int _intervalMin;

  @override
  void initState() {
    super.initState();
    final profile = _p.profile;
    _weight = profile.weight;
    _goalMl = profile.dailyGoalMl;
    _reminderStyle = profile.reminderStyle;
    _notificationsEnabled = profile.notificationsEnabled;
    _exerciseReminder = profile.exerciseReminderEnabled;
    _meetingPause = profile.meetingPauseEnabled;
    _morningPlan = profile.morningPlanEnabled;
    _wakeTime = profile.wakeTime;
    _bedTime = profile.bedTime;
    _intervalMin = profile.reminderIntervalMin;
  }

  void _save() {
    final profile = _p.profile;
    profile.weight = _weight;
    profile.dailyGoalMl = _goalMl;
    profile.reminderStyle = _reminderStyle;
    profile.notificationsEnabled = _notificationsEnabled;
    profile.exerciseReminderEnabled = _exerciseReminder;
    profile.meetingPauseEnabled = _meetingPause;
    profile.morningPlanEnabled = _morningPlan;
    profile.wakeTime = _wakeTime;
    profile.bedTime = _bedTime;
    profile.reminderIntervalMin = _intervalMin;
    _p.updateProfile(profile);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('设置已保存 ✓'),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBasicSettings(),
                  _buildReminderSwitches(),
                  _buildReminderTime(),
                  _buildTestButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgSection,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          const Text('个人设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildBasicSettings() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('⚙️', '基本设置'),
          const SizedBox(height: 16),

          _label('每日饮水目标'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _goalMl.toDouble(),
                  min: 1500, max: 4000, divisions: 25,
                  onChanged: (v) => setState(() => _goalMl = v.round()),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_goalMl}ml',
                    style: AppColors.monoStyle(AppColors.blue).copyWith(fontSize: 13)),
              ),
            ],
          ),

          const SizedBox(height: 14),
          _label('体重（联动推荐目标）'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weight,
                  min: 40, max: 120, divisions: 80,
                  onChanged: (v) => setState(() {
                    _weight = v;
                    _goalMl = (v * 35).round().clamp(1500, 4000);
                  }),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSection,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_weight.round()}kg',
                    style: AppColors.monoStyle(AppColors.textSecondary).copyWith(fontSize: 13)),
              ),
            ],
          ),

          const SizedBox(height: 14),
          _label('提醒风格'),
          const SizedBox(height: 8),
          _styleChips(),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('保存设置')),
          ),
        ],
      ),
    );
  }

  Widget _styleChips() {
    final styles = [('💝', '温柔'), ('😄', '活泼'), ('📢', '严肃')];
    return Wrap(
      spacing: 8,
      children: styles.map((s) {
        final isSelected = s.$2 == _reminderStyle;
        return GestureDetector(
          onTap: () => setState(() => _reminderStyle = s.$2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.blue : AppColors.bgSection,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${s.$1} ${s.$2}',
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

  Widget _buildReminderSwitches() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔔', '提醒开关'),
          const SizedBox(height: 4),
          _switchRow('推送通知', '锁屏显示喝水提醒', Icons.notifications_outlined,
              AppColors.blue, _notificationsEnabled,
              (v) => setState(() => _notificationsEnabled = v)),
          _switchRow('运动后增强提醒', '运动结束立即推送', Icons.directions_run,
              AppColors.orange, _exerciseReminder,
              (v) => setState(() => _exerciseReminder = v)),
          _switchRow('会议期间暂停', '日历有会议时暂停', Icons.event_available,
              AppColors.purple, _meetingPause,
              (v) => setState(() => _meetingPause = v)),
          _switchRow('早间规划提醒', '每天 8:00 提示输入安排', Icons.wb_sunny_outlined,
              AppColors.green, _morningPlan,
              (v) => setState(() => _morningPlan = v), showDivider: false),
        ],
      ),
    );
  }

  Widget _switchRow(
    String title,
    String desc,
    IconData icon,
    Color iconColor,
    bool value,
    ValueChanged<bool> onChanged, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    Text(desc,
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        if (showDivider)
          Container(height: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _buildReminderTime() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('⏰', '提醒时间'),
          const SizedBox(height: 16),

          _timeRow('起床时间', _wakeTime, (t) => setState(() => _wakeTime = t)),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _timeRow('就寝时间', _bedTime, (t) => setState(() => _bedTime = t)),

          const SizedBox(height: 16),
          _label('提醒间隔'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [30, 60, 90, 120].map((min) {
              final isSelected = min == _intervalMin;
              final label = min == 30 ? '30分钟' : min == 60 ? '1小时' : min == 90 ? '1.5小时' : '2小时';
              return GestureDetector(
                onTap: () => setState(() => _intervalMin = min),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.blue : AppColors.bgSection,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '将在 $_wakeTime ~ $_bedTime 间每${_intervalLabelStr(_intervalMin)}提醒',
                    style: const TextStyle(fontSize: 12, color: AppColors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRow(String label, String time, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const Spacer(),
          GestureDetector(
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(time, style: AppColors.monoStyle(AppColors.blue).copyWith(fontSize: 15)),
                  const SizedBox(width: 6),
                  const Icon(Icons.access_time, size: 15, color: AppColors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🧪', '模拟测试'),
          const SizedBox(height: 4),
          const Text('点击按钮体验喝水提醒效果',
              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showTestReminder,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
              icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 18),
              label: const Text('触发喝水提醒'),
            ),
          ),
        ],
      ),
    );
  }

  void _showTestReminder() {
    final messages = [
      '距上次喝水已过 90 分钟，来一杯吧 💧',
      '工作再忙也要记得喝水哦 🌊',
      '今天天气干燥，记得多补充水分 🌬',
    ];
    final msg = (messages..shuffle()).first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('💧', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('喝水提醒',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        content: Text(msg,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后', style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () {
              _p.addDrink(250, desc: '提醒后补水');
              Navigator.pop(ctx);
            },
            child: const Text('喝了 250ml'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String emoji, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 0.5,
                )),
          ],
        ),
      );

  Widget _label(String text) => Text(text,
      style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ));

  String _intervalLabelStr(int minutes) {
    if (minutes == 30) return '30分钟';
    if (minutes == 60) return '1小时';
    if (minutes == 90) return '1.5小时';
    return '2小时';
  }
}
