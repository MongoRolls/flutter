import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/progress_ring.dart';

class HomeScreen extends StatefulWidget {
  final UserProvider userProvider;

  const HomeScreen({super.key, required this.userProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ringAnimController;
  late Animation<double> _ringAnim;

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
    _ringAnimController.forward();
    _p.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _p.removeListener(_onDataChanged);
    _ringAnimController.dispose();
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
          Container(
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
    return GlassCard(
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
              Container(
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
                    Text(
                      '还差 ${_p.remainingMl}ml',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
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
    );
  }

  Widget _buildMiniStats() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          _miniStatCard('${_p.logs.length}', '今日打卡', AppColors.blue, AppColors.blueLight),
          const SizedBox(width: 10),
          _miniStatCard('7', '🔥连续天数', AppColors.orange, AppColors.orangeLight),
          const SizedBox(width: 10),
          _miniStatCard(
            '${_scheduleItems.where((s) => s.status == 'pending').length}',
            '待完成',
            AppColors.textHint,
            AppColors.bgSection,
          ),
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

  Widget _buildScheduleCard() {
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
              const Text('今日时间表',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('AI 生成',
                    style: TextStyle(fontSize: 10, color: AppColors.blue, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._scheduleItems.map(_buildScheduleRow),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(_ScheduleItem item) {
    Color bgColor;
    Color? borderColor;
    Widget statusWidget;

    switch (item.status) {
      case 'done':
        bgColor = AppColors.bgSection;
        borderColor = null;
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('✓',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green)),
        );
      case 'current':
        bgColor = AppColors.blueLight;
        borderColor = AppColors.blue.withValues(alpha: 0.3);
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('现在',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
        );
      default:
        bgColor = Colors.transparent;
        borderColor = null;
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.bgSection,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('待',
              style: TextStyle(fontSize: 10, color: AppColors.textHint)),
        );
    }

    return Opacity(
      opacity: item.status == 'pending' ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(item.time,
                  style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textHint)),
            ),
            const SizedBox(width: 8),
            Text(item.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.desc,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ),
            Text('${item.ml}ml',
                style: AppTheme.monoStyle.copyWith(fontSize: 12, color: AppColors.blue)),
            const SizedBox(width: 8),
            statusWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCalendar(DateTime now) {
    final today = now.day;
    final hits = {1, 2, 3, 5, 6, 8, 9, 10, 11, 12};

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
              Text('🔥 连续 ${hits.where((d) => d < today).length} 天',
                  style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List.generate(31, (i) {
              final d = i + 1;
              Color bg;
              Color textColor;
              BoxDecoration deco;

              if (d == today) {
                deco = BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.4), blurRadius: 8)],
                );
                textColor = Colors.white;
              } else if (d < today && hits.contains(d)) {
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
                bg = AppColors.bgSection;
                deco = BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8));
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

  List<_ScheduleItem> get _scheduleItems {
    final hour = DateTime.now().hour;
    return [
      _ScheduleItem('07:30', '💧', '晨起空腹温水', 300, hour > 7 ? 'done' : 'pending'),
      _ScheduleItem('09:00', '☕', '上午提神咖啡', 200, hour > 9 ? 'done' : (hour >= 9 ? 'current' : 'pending')),
      _ScheduleItem('10:30', '💧', '工作间隙水', 250, hour > 10 ? 'done' : (hour >= 10 ? 'current' : 'pending')),
      _ScheduleItem('12:15', '🥛', '午餐牛奶', 200, hour > 12 ? 'done' : (hour >= 12 ? 'current' : 'pending')),
      _ScheduleItem('14:30', '💧', '下午补水', 300, hour > 14 ? 'done' : (hour >= 14 ? 'current' : 'pending')),
      _ScheduleItem('16:00', '💧', '会议后补水', 250, hour > 16 ? 'done' : (hour >= 16 ? 'current' : 'pending')),
      _ScheduleItem('17:30', '🏃', '健身前补水', 300, hour > 17 ? 'done' : (hour >= 17 ? 'current' : 'pending')),
      _ScheduleItem('19:00', '💧', '运动后补水', 400, hour > 19 ? 'done' : (hour >= 19 ? 'current' : 'pending')),
      _ScheduleItem('21:00', '💧', '睡前温水', 200, hour > 21 ? 'done' : (hour >= 21 ? 'current' : 'pending')),
    ];
  }
}

class _ScheduleItem {
  final String time;
  final String icon;
  final String desc;
  final int ml;
  final String status;

  _ScheduleItem(this.time, this.icon, this.desc, this.ml, this.status);
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
