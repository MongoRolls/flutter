import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SuggestionChips extends StatelessWidget {
  final void Function(String text) onSuggestionTap;

  static const defaultSuggestions = [
    '今天该喝多少水？',
    '帮我制定喝水计划',
    '我的饮水习惯怎么样？',
  ];

  const SuggestionChips({super.key, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: defaultSuggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final suggestion = defaultSuggestions[i];
          return GestureDetector(
            onTap: () => onSuggestionTap(suggestion),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.blueBorder, width: 1),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
