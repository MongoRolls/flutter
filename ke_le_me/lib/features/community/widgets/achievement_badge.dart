import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/achievement.dart';

/// 成就徽章（已解锁=彩色，未解锁=灰色模糊）
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementBadge({super.key, required this.achievement, this.onTap});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF29B6F6).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji 图标
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  achievement.iconEmoji,
                  style: TextStyle(
                    fontSize: 32,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                if (!unlocked)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: const SizedBox(width: 40, height: 40),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: unlocked
                    ? const Color(0xFF1A2340)
                    : const Color(0xFFBDBDBD),
              ),
            ),
            const SizedBox(height: 2),
            if (unlocked && achievement.unlockedAt != null)
              Text(
                '${achievement.unlockedAt!.month}/${achievement.unlockedAt!.day}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF90A4AE)),
              )
            else
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD)),
              ),
          ],
        ),
      ),
    );
  }
}
