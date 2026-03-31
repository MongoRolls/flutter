import 'package:flutter/material.dart';

import '../../../common/widgets/app_modal_sheet.dart';
import '../../../core/theme/app_theme.dart';

/// 添加好友成功后的「邀请好友接收提醒」面板。
///
/// 返回 `true` 表示用户选择开启邀请，`false` 为跳过或关闭。
Future<bool?> showFriendPushInviteSheet({
  required BuildContext context,
  required String friendDisplayName,
}) {
  return showAppModalSheet<bool>(
    context: context,
    builder: (ctx) => _FriendPushInviteBody(friendDisplayName: friendDisplayName),
  );
}

class _FriendPushInviteBody extends StatefulWidget {
  const _FriendPushInviteBody({required this.friendDisplayName});

  final String friendDisplayName;

  @override
  State<_FriendPushInviteBody> createState() => _FriendPushInviteBodyState();
}

class _FriendPushInviteBodyState extends State<_FriendPushInviteBody> {
  bool _inviteOn = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blueLight.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.blueDark,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '邀请好友接收提醒',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '开启后，我们会向「${widget.friendDisplayName}」发送喝水提醒邀请，'
          '对方可在 App 内收到。',
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '向好友发送提醒邀请',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                  ),
                ),
              ),
              Switch(
                value: _inviteOn,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.blue,
                onChanged: (v) => setState(() => _inviteOn = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '请提醒对方在本机开启通知权限，以便及时收到提醒。',
          style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.35),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('跳过'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_inviteOn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
