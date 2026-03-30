import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/care_contact.dart';

/// 队友卡片（组队挑战方向：仅展示队友信息，不含发送提醒/进度环等旧关怀 UI）
class CareContactCard extends StatelessWidget {
  final CareContact contact;
  final VoidCallback? onRemove;

  const CareContactCard({super.key, required this.contact, this.onRemove});

  List<Color> get _avatarGradient => switch (contact.relationship) {
    'family' => [AppColors.pinkLight, const Color(0xFFF06292)],
    _ => [const Color(0xFF81C784), AppColors.greenSoft],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _avatarGradient,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              contact.avatarEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          // 名字 + 关系
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.relationshipLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          // 移除按钮（可选）
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
