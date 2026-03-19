import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_provider.dart';
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
    _celebrateAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _celebrateController,
      curve: Curves.easeInOut,
    ));

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
    final now = DateTime.now();
    if (_lastLogoTap == null || now.difference(_lastLogoTap!) > const Duration(seconds: 2)) {
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
          content: Text('再点 $remaining 次进入调试模式',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _QuickDrinkSheet(
        onDrink: (ml) {
          _p.addDrink(ml, desc: '快速补水');
          Navigator.pop(ctx);
          _ringAnimController.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('💧 '),
                  Text('已记录 ${ml}ml，继续加油！',
                      style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ),
              backgroundColor: AppColors.bgCard,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  const SizedBox(height: 20),
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
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
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
                child: Text('渴',
                    style: GoogleFonts.notoSansSc(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.blue)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('渴了么',
                  style: GoogleFonts.notoSansSc(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('KE LE ME',
                  style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.textHint)),
            ],
          ),
          const Spacer(),
          _headerBtn(Icons.smart_toy_outlined, () => Navigator.pushNamed(context, '/chat')),
          const SizedBox(width: 8),
          _headerBtn(Icons.notifications_outlined, () {}),
          const SizedBox(width: 8),
          _headerBtn(Icons.settings_outlined, () => Navigator.pushNamed(context, '/settings')),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgSection,
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildHeroCard(String greeting, String name, DateTime now) {
    final pct = (_p.progress * 100).round();
    return AnimatedBuilder(
      animation: _celebrateAnim,
      builder: (_, child) => Transform.scale(
        scale: _celebrateAnim.value,
        child: child,
      ),
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
                      Text('👋 $greeting，$name',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${now.year}年${now.month}月${now.day}日',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Container(
                    key: ValueKey(pct >= 100),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pct >= 100 ? AppColors.greenLight : AppColors.blueLight,
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
                              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '目标 ${_p.profile.dailyGoalMl}ml',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
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
                              Text('喝水打卡',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
          _miniStatCard('${_p.logs.length}', '今日打卡', AppColors.blue, AppColors.blueLight),
          const SizedBox(width: 10),
          _miniStatCard('${_p.streakDays}', '🔥连续天数', AppColors.orange, AppColors.orangeLight),
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
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
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
                      fontSize: 15, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                textAlign: TextAlign.center),
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
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
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
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.blue),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('ml',
                      style: GoogleFonts.spaceMono(
                          fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.textHint)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('已喝水量',
                style: TextStyle(fontSize: 10, color: AppColors.textHint),
                textAlign: TextAlign.center),
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
                width: 4, height: 16,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('今日饮水记录',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              if (logs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('共 ${_p.todayMl}ml',
                      style: const TextStyle(fontSize: 10, color: AppColors.blue, fontWeight: FontWeight.w600)),
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
              final slideAnim = Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _entranceController,
                curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
              ));
              final fadeAnim = CurvedAnimation(
                parent: _entranceController,
                curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOut),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                  Text('立即打卡',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
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
        border: isLatest ? Border.all(color: AppColors.blue.withValues(alpha: 0.25)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(log.time,
                style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textHint)),
          ),
          const SizedBox(width: 8),
          Text(log.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(log.description,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text('+${log.ml}ml',
              style: AppTheme.monoStyle.copyWith(
                fontSize: 12,
                color: isLatest ? AppColors.blue : AppColors.textSecondary,
                fontWeight: isLatest ? FontWeight.w700 : FontWeight.w400,
              )),
          const SizedBox(width: 8),
          if (isLatest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('最新',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('✓',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green)),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar(DateTime now) {
    final today = now.day;
    final monthlyHits = _p.monthlyHits;
    final goalMl = _p.profile.dailyGoalMl;
    // 获取本月天数
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // 达标天数
    final achievedDays = monthlyHits.entries
        .where((e) => e.key < today && e.value >= goalMl)
        .length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(
                  color: AppColors.blue, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              const Text('本月打卡',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              Text('🔥 连续 ${_p.streakDays} 天',
                  style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List.generate(daysInMonth, (i) {
              final d = i + 1;
              Color textColor;
              BoxDecoration deco;
              final dayMl = monthlyHits[d] ?? 0;
              final achieved = dayMl >= goalMl;

              if (d == today) {
                deco = BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.4), blurRadius: 8)],
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
                textColor = AppColors.divider;
              }

              return Container(
                width: 34, height: 34,
                decoration: deco,
                child: Center(
                  child: Text(
                    '$d',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: d == today ? FontWeight.w700 : FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(AppColors.blue, '达标'),
              const SizedBox(width: 12),
              _legendDot(AppColors.bgSection, '未达标'),
              const Spacer(),
              Text('本月 $achievedDays 天达标',
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      ],
    );
  }

}

class _QuickDrinkSheet extends StatelessWidget {
  final ValueChanged<int> onDrink;

  const _QuickDrinkSheet({required this.onDrink});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 18),
          const Text('💧 快速记录饮水',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('选择饮水量', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 16),
          Row(
            children: [150, 200, 250, 350, 500].map((ml) {
              final isDefault = ml == 250;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onDrink(ml),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDefault ? AppColors.blue : AppColors.blueLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${ml}ml',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDefault ? Colors.white : AppColors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onDrink(250),
              child: const Text('✓ 喝了 250ml'),
            ),
          ),
        ],
      ),
    );
  }
}
