import 'package:flutter/material.dart';

import '../../../common/widgets/scroll_wheel_time_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/wake_bed_time.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_version.dart';
import '../../../common/widgets/glass_card.dart';
import '../widgets/voice_tone_prefs.dart';
import 'health_archive_screen.dart';
import 'watch_preview_screen.dart';

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
  late String _wakeTime;
  late String _bedTime;
  late int _intervalMin;
  String _voiceToneId = VoiceTonePrefs.defaultId;

  int _debugTapCount = 0;
  DateTime? _lastDebugTap;

  @override
  void initState() {
    super.initState();
    final profile = _p.profile;
    _weight = profile.weight;
    _goalMl = profile.dailyGoalMl;
    _reminderStyle = profile.reminderStyle;
    _notificationsEnabled = profile.notificationsEnabled;
    _wakeTime = profile.wakeTime;
    _bedTime = profile.bedTime;
    _intervalMin = profile.reminderIntervalMin;
    _loadVoiceToneId();
  }

  Future<void> _loadVoiceToneId() async {
    final id = await VoiceTonePrefs.getSelectedId();
    if (!mounted) return;
    setState(() => _voiceToneId = id);
  }

  void _onSettingsWakeTimePicked(String t) {
    final r = WakeBedTime.afterWakePick(newWakeHhMm: t, bedHhMm: _bedTime);
    setState(() {
      _wakeTime = r.wake;
      _bedTime = r.bed;
    });
    if (r.snackMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r.snackMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSettingsBedTimePicked(String t) {
    final r = WakeBedTime.afterBedPick(wakeHhMm: _wakeTime, newBedHhMm: t);
    setState(() {
      _wakeTime = r.wake;
      _bedTime = r.bed;
    });
    if (r.snackMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r.snackMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _save() async {
    final profile = _p.profile;
    profile.weight = _weight;
    profile.dailyGoalMl = _goalMl;
    profile.reminderStyle = _reminderStyle;
    profile.notificationsEnabled = _notificationsEnabled;
    profile.wakeTime = _wakeTime;
    profile.bedTime = _bedTime;
    profile.reminderIntervalMin = _intervalMin;
    _p.updateProfile(profile);

    // 根据通知开关状态调度或取消通知
    try {
      if (_notificationsEnabled) {
        final granted = await NotificationService.instance.requestPermission();
        if (!mounted) return;
        if (granted) {
          await NotificationService.instance.scheduleReminders(
            wakeTime: _wakeTime,
            bedTime: _bedTime,
            intervalMin: _intervalMin,
            reminderStyle: _reminderStyle,
          );
          if (!mounted) return;
        }
      } else {
        await NotificationService.instance.cancelAll();
        if (!mounted) return;
      }
    } catch (e) {
      debugPrint('Error updating notifications: $e');
      if (!mounted) return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              '设置已保存 ✓',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
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
                  _buildWatchPreviewEntry(),
                  _buildReminderTime(),
                  _buildHealthArchive(),
                  _buildTestButton(),
                  _buildVersionInfo(),
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
      decoration: AppDecorations.topBar,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgSection,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '个人设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
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
                  min: 1500,
                  max: 4000,
                  divisions: 25,
                  onChanged: (v) => setState(() => _goalMl = v.round()),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_goalMl}ml',
                  style: AppColors.monoStyle(
                    AppColors.blue,
                  ).copyWith(fontSize: 13),
                ),
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
                  min: 40,
                  max: 120,
                  divisions: 80,
                  onChanged: (v) => setState(() {
                    _weight = v;
                    _goalMl = (v * 35).round().clamp(1500, 4000);
                  }),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSection,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_weight.round()}kg',
                  style: AppColors.monoStyle(
                    AppColors.textSecondary,
                  ).copyWith(fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          _label('提醒风格'),
          const SizedBox(height: 8),
          _styleChips(),

          const SizedBox(height: 14),
          _label('音色'),
          const SizedBox(height: 8),
          _voiceToneChips(),

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

  /// 与 [_styleChips] 同款：音色预设 Chip，选中即写入 [VoiceTonePrefs]。
  Widget _voiceToneChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VoiceTonePrefs.presets.map((preset) {
        final isSelected = preset.id == _voiceToneId;
        return GestureDetector(
          onTap: () async {
            await VoiceTonePrefs.setSelectedId(preset.id);
            if (!mounted) return;
            setState(() => _voiceToneId = preset.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.blue : AppColors.bgSection,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${preset.emoji} ${preset.title}',
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
          _switchRow(
            '推送通知',
            '锁屏显示喝水提醒',
            Icons.notifications_outlined,
            AppColors.blue,
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
            showDivider: false,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.watch_outlined,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '智能手表：提醒由手机发出，经系统同步到手表显示；无需单独安装手表版。若表上无提醒，请在系统或穿戴 App 中开启对本应用的通知，并打开「同步到手表」。',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchPreviewEntry() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('⌚', 'Apple Watch'),
          const SizedBox(height: 4),
          const Text(
            '手表端能力预览（规划中），无独立安装包',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        WatchPreviewScreen(userProvider: widget.userProvider),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.watch_outlined,
                        size: 18,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '查看手表预览',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '表盘与通知样式示意（占位）',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textHint,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                width: 36,
                height: 36,
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        if (showDivider) Container(height: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _buildReminderTime() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('⏰', '提醒时间'),
          const SizedBox(height: 6),
          const Text(
            '同一天内起床须早于就寝；与引导页相同的时间滚轮',
            style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.35),
          ),
          const SizedBox(height: 12),

          _timeRow(
            '起床时间',
            _wakeTime,
            _onSettingsWakeTimePicked,
          ),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _timeRow(
            '就寝时间',
            _bedTime,
            _onSettingsBedTimePicked,
          ),

          const SizedBox(height: 16),
          _label('提醒间隔'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [30, 60, 90, 120].map((min) {
              final isSelected = min == _intervalMin;
              final label = min == 30
                  ? '30分钟'
                  : min == 60
                  ? '1小时'
                  : min == 90
                  ? '1.5小时'
                  : '2小时';
              return GestureDetector(
                onTap: () => setState(() => _intervalMin = min),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.blue : AppColors.bgSection,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await showScrollWheelTimePicker(
                context,
                initialHhMm: time,
                onConfirm: onChanged,
              );
              if (!mounted) return;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    time,
                    style: AppColors.monoStyle(
                      AppColors.blue,
                    ).copyWith(fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.access_time,
                    size: 15,
                    color: AppColors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthArchive() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🧠', 'AI 健康档案'),
          const SizedBox(height: 4),
          const Text(
            'AI 助手从对话中记住的信息',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HealthArchiveScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.folder_outlined, size: 18),
              label: const Text('查看健康档案'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blue, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
          const Text(
            '点击按钮体验喝水提醒效果',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showTestReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
              ),
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: const Text('触发喝水提醒'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTestReminder() async {
    try {
      await NotificationService.instance.showTestNotification(
        reminderStyle: _reminderStyle,
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }

  void _onVersionTap() {
    final now = DateTime.now();
    if (_lastDebugTap != null && now.difference(_lastDebugTap!).inSeconds > 3) {
      _debugTapCount = 0;
    }
    _lastDebugTap = now;
    _debugTapCount++;
    if (_debugTapCount >= 5) {
      _debugTapCount = 0;
      Navigator.pushNamed(context, '/debug');
    }
  }

  Widget _buildVersionInfo() {
    return GestureDetector(
      onTap: _onVersionTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Text(
              '渴了么',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              AppVersion.display,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'SpaceMono',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              AppVersion.buildDate,
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );

  String _intervalLabelStr(int minutes) {
    if (minutes == 30) return '30分钟';
    if (minutes == 60) return '1小时';
    if (minutes == 90) return '1.5小时';
    return '2小时';
  }
}
