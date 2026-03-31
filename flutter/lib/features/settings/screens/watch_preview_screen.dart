import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../common/widgets/glass_card.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';

/// 设置 → Apple Watch：仅 UI 展示，无后端、无真实 watchOS 能力。
/// 表壳等资源就绪后替换 [_WatchShellPlaceholder]。
class WatchPreviewScreen extends StatefulWidget {
  const WatchPreviewScreen({super.key, required this.userProvider});

  final UserProvider userProvider;

  @override
  State<WatchPreviewScreen> createState() => _WatchPreviewScreenState();
}

class _WatchPreviewScreenState extends State<WatchPreviewScreen> {
  bool _colorProgress = true;
  int _faceIndex = 0;
  int _notificationStyleIndex = 0;
  int _presetIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.userProvider,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      _buildBanner(),
                      const SizedBox(height: 12),
                      _buildColorProgressSwitch(),
                      const SizedBox(height: 12),
                      _sectionFaces(),
                      const SizedBox(height: 12),
                      _sectionNotificationStyles(),
                      const SizedBox(height: 12),
                      _sectionPresetFaces(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const Expanded(
            child: Text(
              'Apple Watch',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '以下为能力预览，功能规划中；提醒仍由手机发出并同步至手表。',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorProgressSwitch() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF29B6F6),
                  Color(0xFF66BB6A),
                  Color(0xFFFFB74D),
                ],
              ).createShader(bounds),
              child: const Icon(Icons.palette_outlined, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '彩色进度',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '表盘上以渐变展示完成度（预览）',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _colorProgress,
            onChanged: (v) => setState(() => _colorProgress = v),
          ),
        ],
      ),
    );
  }

  Widget _sectionFaces() {
    final p = widget.userProvider;
    final pct = (p.progress * 100).round();
    final today = p.todayMl;
    final goal = p.profile.dailyGoalMl;
    final remain = (goal - today).clamp(0, goal);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('首页表盘'),
          const SizedBox(height: 4),
          Text(
            '今日 $today ml / 目标 $goal ml · 剩余 $remain ml',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              _faceCell(
                index: 0,
                label: '圆环',
                child: _MiniRingPreview(
                  percent: pct,
                  colorProgress: _colorProgress,
                ),
              ),
              _faceCell(
                index: 1,
                label: '角色轮廓',
                child: _MiniSilhouettePlaceholder(percent: pct),
              ),
              _faceCell(
                index: 2,
                label: '快捷记录',
                child: _MiniQuickLogPlaceholder(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _faceCell({
    required int index,
    required String label,
    required Widget child,
  }) {
    final selected = _faceIndex == index;
    return SizedBox(
      width: 148,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _faceIndex = index),
            child: _WatchShellPlaceholder(child: child),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected)
                const Icon(Icons.check_circle, size: 16, color: AppColors.blue),
              if (selected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.blue : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionNotificationStyles() {
    const labels = ['图文进度', '文本进度', '推送语'];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('通知样式'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: List.generate(3, (i) {
              final selected = _notificationStyleIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _notificationStyleIndex = i),
                child: SizedBox(
                  width: 148,
                  child: Column(
                    children: [
                      _WatchShellPlaceholder(
                        child: _NotificationStylePlaceholder(variant: i),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.blue,
                            ),
                          if (selected) const SizedBox(width: 4),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected
                                  ? AppColors.blue
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sectionPresetFaces() {
    const labels = ['复杂功能表盘', '指针表盘'];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('预设表盘'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: List.generate(2, (i) {
              final selected = _presetIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _presetIndex = i),
                child: SizedBox(
                  width: 160,
                  child: Column(
                    children: [
                      _WatchShellPlaceholder(
                        child: _PresetFacePlaceholder(variant: i),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.blue,
                            ),
                          if (selected) const SizedBox(width: 4),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected
                                  ? AppColors.blue
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// 表壳：暂无 PNG 时使用虚线框 + 表冠示意。
class _WatchShellPlaceholder extends StatelessWidget {
  const _WatchShellPlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  color: const Color(0xFF2C2C2E),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(6),
                    child: child,
                  ),
                ),
              ),
              Positioned(
                right: -4,
                top: w * 0.32,
                child: Container(
                  width: 5,
                  height: w * 0.22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3C),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniRingPreview extends StatelessWidget {
  const _MiniRingPreview({
    required this.percent,
    required this.colorProgress,
  });

  final int percent;
  final bool colorProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 72,
          width: 72,
          child: CustomPaint(
            painter: _RingPainter(
              progress: (percent / 100).clamp(0.0, 1.0),
              colorProgress: colorProgress,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: AppColors.monoStyle(Colors.white).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    percent >= 100 ? '目标达成' : '继续加油',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.colorProgress});

  final double progress;
  final bool colorProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const stroke = 6.0;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    if (colorProgress) {
      final gradient = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: const [
          Color(0xFF29B6F6),
          Color(0xFF66BB6A),
          Color(0xFFFFB74D),
          Color(0xFF29B6F6),
        ],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
    } else {
      final paint = Paint()
        ..color = AppColors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.colorProgress != colorProgress;
  }
}

class _MiniSilhouettePlaceholder extends StatelessWidget {
  const _MiniSilhouettePlaceholder({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.5),
                      AppColors.green.withValues(alpha: 0.45),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.pets_outlined,
                  color: Colors.white54,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniQuickLogPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('水', '100'),
      ('咖啡', '200'),
      ('牛奶', '330'),
      ('茶', '150'),
    ];
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.4,
        children: items
            .map(
              (e) => Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      e.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${e.$2}ml',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NotificationStylePlaceholder extends StatelessWidget {
  const _NotificationStylePlaceholder({required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '喝水提醒',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (variant == 0) ...[
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFF29B6F6), Color(0xFF66BB6A)],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '+100ml 水',
                style: TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ] else if (variant == 1) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '水',
                      style: TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '咖啡',
                      style: TextStyle(color: Colors.white70, fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              '该喝水了！让身体保持好状态。',
              style: TextStyle(color: Colors.white70, fontSize: 9, height: 1.2),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '记录',
                style: TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetFacePlaceholder extends StatelessWidget {
  const _PresetFacePlaceholder({required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    if (variant == 0) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '周四 28',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 9,
                  ),
                ),
                Text(
                  '1,200ml',
                  style: AppColors.monoStyle(Colors.white70).copyWith(fontSize: 8),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (i) => Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    [Icons.bolt, Icons.water_drop, Icons.percent][i],
                    size: 12,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: const Icon(Icons.schedule, color: Colors.white38, size: 22),
          ),
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '饮水',
                style: AppColors.monoStyle(Colors.white).copyWith(fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
