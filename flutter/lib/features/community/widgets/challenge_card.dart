import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/challenge.dart';

/// 组队 / 本地打卡挑战卡片
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onAckResult;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onJoin,
    this.onLeave,
    this.onAckResult,
  });

  String get _rewardEmoji => switch (challenge.rewardBadgeId) {
    'team_challenge' => '🤝',
    'buddy_plan' => '🤝',
    'iron_man' => '🏆',
    'early_bird' => '🌅',
    _ => '🎖️',
  };

  @override
  Widget build(BuildContext context) {
    final isServer = challenge.fromServer;
    final settled = challenge.status == 'settled';
    final showAck =
        settled &&
        challenge.resultAcknowledgedAt == null &&
        onAckResult != null;

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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: settled
                      ? AppColors.yellowLight
                      : AppColors.greySection,
                ),
                alignment: Alignment.center,
                child: Text(
                  _rewardEmoji,
                  style: TextStyle(
                    fontSize: 18,
                    color: settled ? null : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (isServer) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(
                  '状态 ${challenge.status ?? '-'}',
                  AppColors.blue.withValues(alpha: 0.12),
                ),
                if (challenge.memberCount != null)
                  _chip('${challenge.memberCount} 人', AppColors.greySection),
                if (challenge.selfContributed == true)
                  Text(
                    challenge.goalType == 'team_total' ? '团队目标已达成' : '今日已达标',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenSoft,
                    ),
                  )
                else if (challenge.selfContributed == false)
                  Text(
                    challenge.goalType == 'team_total' ? '团队目标未达成' : '今日未达标',
                    style: const TextStyle(fontSize: 12, color: AppColors.orange),
                  ),
              ],
            ),
            if (challenge.teamProgressMl != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: challenge.progressRatio.clamp(0.0, 1.0),
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          settled ? AppColors.greenSoft : AppColors.blue,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${challenge.teamProgressMl} ml',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (challenge.inviteCode != null &&
                challenge.inviteCode!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '邀请码 ${challenge.inviteCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    color: AppColors.blue,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: challenge.inviteCode!),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('邀请码已复制')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: challenge.progressRatio,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        challenge.isCompleted
                            ? AppColors.greenSoft
                            : AppColors.blue,
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
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (onJoin != null && !challenge.isJoined) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onJoin,
                  child: const Text('参加挑战'),
                ),
              ),
            ],
          ],
          if (showAck) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAckResult,
                child: const Text('查看本期成绩'),
              ),
            ),
          ],
          if (onLeave != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onLeave,
                child: const Text(
                  '退出挑战',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}
