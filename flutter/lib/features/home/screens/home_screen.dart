import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/models/drink_preset.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/app_version.dart';
import '../../../common/widgets/app_dialog.dart';
import '../../../common/widgets/app_modal_sheet.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../common/widgets/progress_ring.dart';
import '../widgets/weather_goal_card.dart';

class HomeScreen extends StatefulWidget {
  final UserProvider userProvider;

  const HomeScreen({super.key, required this.userProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const List<String> _weekdayLabels = [
    '日',
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
  ];

  late AnimationController _ringAnimController;
  late Animation<double> _ringAnim;
  late AnimationController _entranceController;
  late AnimationController _celebrateController;
  late Animation<double> _celebrateAnim;

  // 彩蛋：连续点击 logo 5次进入 debug 页
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  UserProvider get _p => widget.userProvider;

  @override
  void initState() {
    super.initState();
    _ringAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnim = CurvedAnimation(
      parent: _ringAnimController,
      curve: Curves.easeOutCubic,
    );

    // 列表入场交错动画
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 达标庆祝弹跳动画
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrateAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(
            parent: _celebrateController,
            curve: Curves.easeInOut,
          ),
        );

    _ringAnimController.forward();
    _entranceController.forward();
    _p.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) {
      // 检查是否刚达标
      if (_p.progress >= 1.0 && !_celebrateController.isAnimating) {
        _celebrateController.forward(from: 0);
      }
      setState(() {});
    }
  }

  void _onLogoTap() {
    if (kReleaseMode) return;
    final now = DateTime.now();
    if (_lastLogoTap == null ||
        now.difference(_lastLogoTap!) > const Duration(seconds: 2)) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    _lastLogoTap = now;

    const total = 5;
    if (_logoTapCount >= total) {
      _logoTapCount = 0;
      Navigator.pushNamed(context, '/debug');
    } else {
      final remaining = total - _logoTapCount;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '再点 $remaining 次进入调试模式',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
        ),
      );
    }
  }

  @override
  void dispose() {
    _p.removeListener(_onDataChanged);
    _ringAnimController.dispose();
    _entranceController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  void _showQuickDrinkSheet() {
    showAppModalSheet<void>(
      context: context,
      builder: (ctx) => _QuickDrinkSheet(
        presets: _p.drinkPresets,
        userProvider: _p,
        onDrink: (preset) {
          _p.addDrink(preset.ml, type: preset.icon, desc: preset.name);
          Navigator.pop(ctx);
          _ringAnimController.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text('${preset.icon} '),
                  Text(
                    '已记录 ${preset.ml}ml，继续加油！',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _p.profile.nickname.isEmpty ? '用户' : _p.profile.nickname;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? '早上好' : (hour < 18 ? '下午好' : '晚上好');

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(name),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeroCard(greeting, name, now),
                  WeatherGoalCard(userProvider: _p),
                  _buildMiniStats(),
                  _buildScheduleCard(),
                  _buildStreakCalendar(now),
                  _buildMonthlyStats(now),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      AppVersion.display,
                      style: TextStyle(
                        color: AppColors.textHint.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontFamily: 'SpaceMono',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: AppDecorations.topBar,
      child: Row(
        children: [
          GestureDetector(
            onTap: _onLogoTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueLight,
              ),
              child: Center(
                child: Text(
                  '渴',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '渴了么',
                style: GoogleFonts.notoSansSc(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'KE LE ME',
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String greeting, String name, DateTime now) {
    final pct = (_p.progress * 100).round();
    return AnimatedBuilder(
      animation: _celebrateAnim,
      builder: (_, child) =>
          Transform.scale(scale: _celebrateAnim.value, child: child),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👋 $greeting，$name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${now.year}年${now.month}月${now.day}日',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Container(
                    key: ValueKey(pct >= 100),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pct >= 100
                          ? AppColors.greenLight
                          : AppColors.blueLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pct >= 100 ? '🎉 已达标！' : '今日 $pct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pct >= 100 ? AppColors.green : AppColors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _ringAnim,
                  builder: (_, child) => ProgressRing(
                    progress: _p.progress * _ringAnim.value,
                    currentMl: _p.todayMl,
                    goalMl: _p.profile.dailyGoalMl,
                    size: 120,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: _p.remainingMl),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (_, value, _) => Text(
                          '还差 ${value}ml',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '目标 ${_p.profile.dailyGoalMl}ml',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showQuickDrinkSheet,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('💧 ', style: TextStyle(fontSize: 14)),
                              Text(
                                '喝水打卡',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStats() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          _miniStatCard(
            '${_p.logs.length}',
            '今日打卡',
            AppColors.blue,
            AppColors.blueLight,
          ),
          const SizedBox(width: 10),
          _miniStatCard(
            '${_p.streakDays}',
            '🔥连续天数',
            AppColors.orange,
            AppColors.orangeLight,
          ),
          const SizedBox(width: 10),
          _miniStatCardMl(_p.todayMl),
        ],
      ),
    );
  }

  Widget _miniStatCard(String num, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
              child: Center(
                child: Text(
                  num,
                  style: GoogleFonts.spaceMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCardMl(int ml) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$ml',
                  style: GoogleFonts.spaceMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'ml',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '已喝水量',
              style: TextStyle(fontSize: 10, color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    final logs = _p.logs;
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
                '今日饮水记录',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (logs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '共 ${_p.todayMl}ml',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (logs.isEmpty)
            _buildEmptyLogsHint()
          else
            ...List.generate(logs.length, (index) {
              final log = logs[index];
              final intervalStart = (index * 0.08).clamp(0.0, 0.7);
              final intervalEnd = (intervalStart + 0.3).clamp(0.0, 1.0);
              final slideAnim =
                  Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _entranceController,
                      curve: Interval(
                        intervalStart,
                        intervalEnd,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  );
              final fadeAnim = CurvedAnimation(
                parent: _entranceController,
                curve: Interval(
                  intervalStart,
                  intervalEnd,
                  curve: Curves.easeOut,
                ),
              );
              return FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: slideAnim,
                  child: _buildDrinkLogRow(log, index == logs.length - 1),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyLogsHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💧', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '今天还没有喝水记录',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '点击上方「喝水打卡」开始记录',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showQuickDrinkSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('💧 ', style: TextStyle(fontSize: 13)),
                  Text(
                    '立即打卡',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkLogRow(DrinkLog log, bool isLatest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isLatest ? AppColors.blueLight : AppColors.bgSection,
        borderRadius: BorderRadius.circular(10),
        border: isLatest
            ? Border.all(color: AppColors.blue.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              log.time,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(log.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              log.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '+${log.ml}ml',
            style: AppTheme.monoStyle.copyWith(
              fontSize: 12,
              color: isLatest ? AppColors.blue : AppColors.textSecondary,
              fontWeight: isLatest ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(width: 8),
          if (isLatest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '最新',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✓',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar(DateTime now) {
    final today = now.day;
    final monthlyHits = _p.monthlyHits;
    final goalMl = _p.profile.dailyGoalMl;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstOfMonth = DateTime(now.year, now.month, 1);
    // 周日起：Dart weekday 周一=1…周日=7 → 周日列索引 0
    final leading = firstOfMonth.weekday % 7;
    final totalSlots = leading + daysInMonth;
    final rowCount = (totalSlots + 6) ~/ 7;

    final achievedDays = monthlyHits.entries
        .where((e) => e.key <= today && e.value >= goalMl)
        .length;

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
                '本月打卡',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '🔥 连续 ${_p.streakDays} 天',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 4.0;
              final maxW = constraints.maxWidth;
              final cellW = (maxW - spacing * 6) / 7;
              final cellSize = cellW.clamp(26.0, 36.0);

              Widget streakDayCell(int d) {
                Color textColor;
                BoxDecoration deco;
                final dayMl = monthlyHits[d] ?? 0;
                final achieved = dayMl >= goalMl;

                if (d == today) {
                  deco = BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  );
                  textColor = Colors.white;
                } else if (d < today && achieved) {
                  deco = BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.blueBorder),
                  );
                  textColor = AppColors.blue;
                } else if (d < today) {
                  deco = BoxDecoration(
                    color: AppColors.bgSection,
                    borderRadius: BorderRadius.circular(8),
                  );
                  textColor = AppColors.textHint;
                } else {
                  deco = BoxDecoration(
                    color: AppColors.bgSection,
                    borderRadius: BorderRadius.circular(8),
                  );
                  textColor = AppColors.textHint;
                }

                return Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: deco,
                  child: Center(
                    child: Text(
                      '$d',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: d == today
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              }

              Widget emptyCell() => SizedBox(width: cellSize, height: cellSize);

              Widget slotAt(int r, int c) {
                final idx = r * 7 + c;
                if (idx < leading) return emptyCell();
                final d = idx - leading + 1;
                if (d > daysInMonth) return emptyCell();
                return streakDayCell(d);
              }

              final gridRows = <Widget>[];
              gridRows.add(
                Row(
                  children: [
                    for (int c = 0; c < 7; c++) ...[
                      if (c > 0) SizedBox(width: spacing),
                      SizedBox(
                        width: cellSize,
                        child: Center(
                          child: Text(
                            _weekdayLabels[c],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
              gridRows.add(SizedBox(height: spacing + 2));

              for (var r = 0; r < rowCount; r++) {
                gridRows.add(
                  Row(
                    children: [
                      for (int c = 0; c < 7; c++) ...[
                        if (c > 0) SizedBox(width: spacing),
                        slotAt(r, c),
                      ],
                    ],
                  ),
                );
                if (r < rowCount - 1) {
                  gridRows.add(SizedBox(height: spacing));
                }
              }

              return Column(children: gridRows);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(AppColors.blue, '达标'),
              const SizedBox(width: 12),
              _legendDot(AppColors.bgSection, '未达标'),
              const Spacer(),
              Text(
                '本月 $achievedDays 天达标',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats(DateTime now) {
    final today = now.day;
    final monthlyHits = _p.monthlyHits;
    final goalMl = _p.profile.dailyGoalMl;

    // 本月总摄入
    final totalMl = monthlyHits.entries
        .where((e) => e.key <= today)
        .fold<int>(0, (sum, e) => sum + e.value);

    // 有摄入记录的天数（打卡天数）
    final checkinDays = monthlyHits.entries
        .where((e) => e.key <= today && e.value > 0)
        .length;

    // 日均摄入：用有记录天数作分母，避免月初或无数据时显示 0
    final avgMl = checkinDays > 0 ? (totalMl / checkinDays).round() : 0;

    // 达标天数
    final achievedDays = monthlyHits.entries
        .where((e) => e.key <= today && e.value >= goalMl)
        .length;

    // 达标率（分母用已过天数，反映整月履约情况）
    final achieveRate = today > 0 ? (achievedDays / today * 100).round() : 0;

    // 本月累计进度（截至今日）
    final monthGoalMl = goalMl * today;
    final totalProgress = monthGoalMl > 0
        ? (totalMl / monthGoalMl).clamp(0.0, 1.0)
        : 0.0;

    // ── 柱状图数据 ──────────────────────────────────────────────
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    double maxY = goalMl.toDouble();
    for (final e in monthlyHits.entries) {
      if (e.key <= today && e.value > maxY) maxY = e.value.toDouble();
    }
    maxY = (maxY * 1.25).ceilToDouble();

    final barGroups = <BarChartGroupData>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final ml = (monthlyHits[d] ?? 0).toDouble();
      final achieved = d <= today && ml >= goalMl;
      final isFuture = d > today;
      barGroups.add(
        BarChartGroupData(
          x: d,
          barRods: [
            BarChartRodData(
              toY: isFuture ? 0 : ml,
              width: daysInMonth <= 20 ? 7 : 5,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
              color: isFuture
                  ? Colors.transparent
                  : achieved
                  ? AppColors.blue
                  : AppColors.greyLight,
            ),
          ],
        ),
      );
    }

    // 每 5 天显示一个 X 轴标签
    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      final d = value.toInt();
      if (d % 5 != 0 && d != 1 && d != daysInMonth) {
        return const SizedBox.shrink();
      }
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          '$d',
          style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.textHint),
        ),
      );
    }

    // 主数值显示：自动选 L 或 ml
    final totalDisplay = totalMl >= 1000
        ? (totalMl / 1000).toStringAsFixed(1)
        : '$totalMl';
    final totalUnit = totalMl >= 1000 ? 'L' : 'ml';
    final avgDisplay = avgMl >= 1000
        ? (avgMl / 1000).toStringAsFixed(1)
        : '$avgMl';
    final avgUnit = avgMl >= 1000 ? 'L' : 'ml';

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 标题行 ─────────────────────────────────────────────
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
                '本月统计',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${now.month} 月数据',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 主指标：总摄入大数字 + 进度环 ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本月总摄入',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          totalDisplay,
                          style: GoogleFonts.spaceMono(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5, left: 4),
                          child: Text(
                            totalUnit,
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 进度条
                    _WaterProgressBar(
                      progress: totalProgress,
                      color: AppColors.blue,
                      bgColor: AppColors.blueLight,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '截至今日累计达成 ${(totalProgress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 进度环
              _WaterRing(
                progress: totalProgress,
                size: 68,
                label: '${(totalProgress * 100).round()}%',
                sublabel: '累计',
                ringColor: AppColors.blue,
                bgColor: AppColors.blueLight,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 3 个次指标横排 ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.bgSection,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                _MiniStat(
                  label: '日均摄入',
                  value: avgDisplay,
                  unit: avgUnit,
                  color: AppColors.skyBright,
                  icon: Icons.show_chart_rounded,
                ),
                _VertDivider(),
                _MiniStat(
                  label: '达标率',
                  value: '$achieveRate',
                  unit: '%',
                  color: AppColors.green,
                  icon: Icons.verified_rounded,
                ),
                _VertDivider(),
                _MiniStat(
                  label: '打卡天数',
                  value: '$checkinDays',
                  unit: '天',
                  color: AppColors.orange,
                  icon: Icons.local_fire_department_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 柱状图标题 ──────────────────────────────────────────
          Row(
            children: [
              const Text(
                '每日摄入趋势',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              _chartLegend(AppColors.blue, '达标'),
              const SizedBox(width: 8),
              _chartLegend(AppColors.greyLight, '未达标'),
              const Spacer(),
              Container(width: 14, height: 1.5, color: AppColors.orange),
              const SizedBox(width: 4),
              const Text(
                '目标线',
                style: TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── 柱状图 ──────────────────────────────────────────────
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: goalMl.toDouble(),
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.textPrimary.withValues(alpha: 0.88),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final ml = rod.toY.toInt();
                      if (ml == 0) return null;
                      return BarTooltipItem(
                        '${group.x}日\n',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '$ml ml',
                            style: const TextStyle(
                              color: AppColors.skyBright,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: _leftTitleWidgets,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 16,
                      getTitlesWidget: bottomTitleWidgets,
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goalMl.toDouble(),
                      color: AppColors.orange,
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                barGroups: barGroups,
                alignment: BarChartAlignment.spaceAround,
              ),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == meta.min || value == meta.max) {
      return const SizedBox.shrink();
    }
    final label = value >= 1000
        ? '${(value / 1000).toStringAsFixed(1)}L'
        : '${value.toInt()}';
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        label,
        style: const TextStyle(fontSize: 8, color: Color(0xFF6B9EC4)),
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF6B9EC4)),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ── 本月统计卡片：辅助组件 ────────────────────────────────────────────────────

/// 环形进度指示器（水波风格）
class _WaterRing extends StatelessWidget {
  const _WaterRing({
    required this.progress,
    required this.size,
    required this.label,
    required this.sublabel,
    required this.ringColor,
    required this.bgColor,
  });

  final double progress;
  final double size;
  final String label;
  final String sublabel;
  final Color ringColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: const TextStyle(fontSize: 9, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 细进度条
class _WaterProgressBar extends StatelessWidget {
  const _WaterProgressBar({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  final double progress;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: 4,
          width: width,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 横排次指标（日均摄入 / 达标率 / 打卡天数）
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceMono(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// 次指标间的竖向分割线
class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: AppColors.divider);
  }
}

class _QuickDrinkSheet extends StatefulWidget {
  final List<DrinkPreset> presets;
  final UserProvider userProvider;
  final ValueChanged<DrinkPreset> onDrink;

  const _QuickDrinkSheet({
    required this.presets,
    required this.userProvider,
    required this.onDrink,
  });

  @override
  State<_QuickDrinkSheet> createState() => _QuickDrinkSheetState();
}

class _QuickDrinkSheetState extends State<_QuickDrinkSheet> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final presets = widget.presets;
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 4 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '💧 快速记录饮水',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showManagePresetsSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.blue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '管理杯子',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '选择你的水杯，点击即可记录',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 16),
          _buildPresetsGrid(presets),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedIndex >= 0 && _selectedIndex < presets.length
                  ? () => widget.onDrink(presets[_selectedIndex])
                  : null,
              child: Text(
                _selectedIndex >= 0 && _selectedIndex < presets.length
                    ? '✓ 喝了 ${presets[_selectedIndex].ml}ml ${presets[_selectedIndex].name}'
                    : '请选择水杯',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsGrid(List<DrinkPreset> presets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 3;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;
        const itemHeight = 96.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(presets.length, (i) {
            final preset = presets[i];
            final isSelected = _selectedIndex == i;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = i);
                widget.onDrink(preset);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: itemWidth,
                height: itemHeight,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue : AppColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? Border.all(color: AppColors.blueDark, width: 2)
                      : Border.all(color: AppColors.blueBorder, width: 1),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(preset.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(
                      preset.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${preset.ml}ml',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _showManagePresetsSheet(BuildContext context) {
    Navigator.pop(context);
    showAppModalSheet<void>(
      context: context,
      builder: (ctx) => _ManagePresetsSheet(userProvider: widget.userProvider),
    );
  }
}

// ── 杯子管理面板 ──

class _ManagePresetsSheet extends StatefulWidget {
  final UserProvider userProvider;
  const _ManagePresetsSheet({required this.userProvider});

  @override
  State<_ManagePresetsSheet> createState() => _ManagePresetsSheetState();
}

class _ManagePresetsSheetState extends State<_ManagePresetsSheet> {
  @override
  Widget build(BuildContext context) {
    final presets = widget.userProvider.drinkPresets;
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 4 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '🛠 管理我的水杯',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await widget.userProvider.resetDrinkPresets();
                  setState(() {});
                },
                child: const Text(
                  '恢复默认',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '长按可删除，点击可编辑',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: presets.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (ctx, i) {
                final p = presets[i];
                return Dismissible(
                  key: ValueKey('preset_${i}_${p.name}_${p.ml}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.red.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.red,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    if (presets.length <= 1) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('至少保留一个杯子')));
                      return false;
                    }
                    return true;
                  },
                  onDismissed: (_) async {
                    await widget.userProvider.removeDrinkPreset(i);
                    setState(() {});
                  },
                  child: ListTile(
                    leading: Text(p.icon, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '${p.ml}ml',
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                    onTap: () =>
                        _showEditPresetDialog(context, index: i, preset: p),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditPresetDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('添加新杯子'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blueBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPresetDialog(
    BuildContext context, {
    int? index,
    DrinkPreset? preset,
  }) {
    final isEditing = preset != null;
    final nameCtrl = TextEditingController(text: preset?.name ?? '');
    final mlCtrl = TextEditingController(text: preset?.ml.toString() ?? '');
    String selectedIcon = preset?.icon ?? '💧';

    const iconOptions = [
      '💧',
      '🥛',
      '🥤',
      '🍵',
      '☕',
      '🫗',
      '🧃',
      '🍶',
      '🥣',
      '🧊',
      '🍺',
      '🫖',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppDialogScaffold(
          insetPadding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          title: Text(isEditing ? '编辑杯子' : '添加新杯子'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择图标',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconOptions.map((icon) {
                    final isActive = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.blueLight
                              : AppColors.bgSection,
                          borderRadius: BorderRadius.circular(10),
                          border: isActive
                              ? Border.all(color: AppColors.blue, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '名称',
                    hintText: '例如：我的保温杯',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mlCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: '容量 (ml)',
                    hintText: '例如：350',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                '取消',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final ml = int.tryParse(mlCtrl.text.trim());
                if (name.isEmpty || ml == null || ml <= 0) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请填写名称和有效容量')));
                  return;
                }
                final newPreset = DrinkPreset(
                  icon: selectedIcon,
                  name: name,
                  ml: ml,
                );
                if (isEditing && index != null) {
                  widget.userProvider.updateDrinkPreset(index, newPreset);
                } else {
                  widget.userProvider.addDrinkPreset(newPreset);
                }
                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(isEditing ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }
}
