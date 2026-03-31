import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/care_contact.dart';

/// 心连心 · 关怀联系人卡片（与全站 GlassCard / 蓝系主色一致）
class CareContactCard extends StatelessWidget {
  final CareContact contact;
  final VoidCallback? onRemove;
  final VoidCallback? onRemindPeer;

  const CareContactCard({
    super.key,
    required this.contact,
    this.onRemove,
    this.onRemindPeer,
  });

  List<Color> get _avatarGradient {
    return switch (contact.relationship) {
      'family' => [AppColors.pinkLight, AppColors.pink.withValues(alpha: 0.85)],
      _ => [AppColors.skyBright, AppColors.blue],
    };
  }

  Color get _statusDotColor {
    if (!contact.hydrationVisible) return AppColors.grey;
    return switch (contact.status) {
      'done' => AppColors.greenSoft,
      'inProgress' => AppColors.orangeWarm,
      _ => AppColors.grey,
    };
  }

  Color get _ringColor {
    final p = contact.progress;
    if (p >= 0.8) return AppColors.greenSoft;
    if (p >= 0.35) return AppColors.orangeWarm;
    return AppColors.red;
  }

  String get _statusLine {
    if (!contact.hydrationVisible) return '对方已隐藏饮水数据';
    final goal = contact.mockDailyGoalMl;
    final today = contact.mockTodayMl;
    if (today >= goal) return '今日 ✓ 已喝 ${today}ml';
    if (today > 0) return '今日 ⚠️ 仅喝了 ${today}ml';
    return '今日 ⚠️ 还没开始喝';
  }

  String get _remindLabel => switch (contact.relationship) {
    'family' => '提醒喝水',
    _ => '提醒对方',
  };

  @override
  Widget build(BuildContext context) {
    final pct = (contact.progress * 100).round().clamp(0, 100);
    final hasRemove = onRemove != null;
    const ringRightReserve = 30.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSection,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, hasRemove ? 12 + ringRightReserve : 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AvatarWithDot(
                      emoji: contact.avatarEmoji,
                      gradientColors: _avatarGradient,
                      dotColor: _statusDotColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBody,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact.relationshipLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: contact.status == 'done'
                                  ? AppColors.greenDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Semantics(
                      label: '今日饮水进度 $pct%',
                      child: _MiniWaterRing(
                        progress: contact.progress,
                        strokeColor: _ringColor,
                        percentLabel: '$pct%',
                      ),
                    ),
                  ],
                ),
                if (contact.friendPushInviteEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.blueLight.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 14,
                          color: AppColors.blueDark,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '已邀请接收提醒',
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blueDark,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (onRemindPeer != null) ...[
                  SizedBox(
                    height: contact.friendPushInviteEnabled ? 10 : 12,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onRemindPeer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blueDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: AppColors.blueBorder.withValues(alpha: 0.9),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        _remindLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasRemove)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(20),
                  child: Tooltip(
                    message: '移除',
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.85),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarWithDot extends StatelessWidget {
  final String emoji;
  final List<Color> gradientColors;
  final Color dotColor;

  const _AvatarWithDot({
    required this.emoji,
    required this.gradientColors,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 迷你饮水进度环（与原型 HTML 小环类似）
class _MiniWaterRing extends StatelessWidget {
  final double progress;
  final Color strokeColor;
  final String percentLabel;

  const _MiniWaterRing({
    required this.progress,
    required this.strokeColor,
    required this.percentLabel,
  });

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeColor: strokeColor,
        ),
        child: Center(
          child: Text(
            percentLabel,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textBody,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeColor,
  });

  final double progress;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final stroke = 3.0;
    final r = (size.shortestSide - stroke) / 2 - 1;

    final bgPaint = Paint()
      ..color = AppColors.greyLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(c, r, bgPaint);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeColor != strokeColor;
  }
}
