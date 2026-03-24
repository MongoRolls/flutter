import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 话术模板选择 Chip（2×2 网格）
class CareTemplateChip extends StatelessWidget {
  final String emoji;
  final String title;
  final String content;
  final bool isSelected;
  final VoidCallback onTap;

  const CareTemplateChip({
    super.key,
    required this.emoji,
    required this.title,
    required this.content,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pinkBg
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.pinkBorder
                : Colors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.pinkDark : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '「$content」',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppColors.pinkDark
                    : const Color(0xFF78909C),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
