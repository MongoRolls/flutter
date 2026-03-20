import 'package:flutter/material.dart';

import '../models/challenge.dart';

/// 挑战卡片
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onJoin;

  const ChallengeCard({super.key, required this.challenge, this.onJoin});

  /// 勋章预览映射
  String get _rewardEmoji => switch (challenge.rewardBadgeId) {
    'buddy_plan' => '🤝',
    'iron_man' => '🏆',
    'early_bird' => '🌅',
    _ => '🎖️',
  };

  @override
  Widget build(BuildContext context) {
    final isCompleted = challenge.isCompleted;
    final isJoined = challenge.isJoined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
              ),
              // 勋章预览
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFF5F5F5),
                ),
                alignment: Alignment.center,
                child: Text(
                  _rewardEmoji,
                  style: TextStyle(
                    fontSize: 18,
                    color: isCompleted ? null : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (isJoined) ...[
            const SizedBox(height: 14),
            // 进度条
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: challenge.progressRatio,
                      backgroundColor: const Color(0xFFE8EFF5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFF29B6F6),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${challenge.currentProgress} / ${challenge.durationDays} 天',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF546E7A),
                  ),
                ),
              ],
            ),
            if (isCompleted) ...[
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🎉 挑战完成！',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF66BB6A),
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (!isJoined) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29B6F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
                child: const Text(
                  '参与挑战',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
