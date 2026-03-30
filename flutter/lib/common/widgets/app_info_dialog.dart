import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog.dart';

/// 标准居中告知框：单主按钮，用于「知道了」类场景。
Future<void> showAppInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonLabel = '知道了',
  bool barrierDismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return AppDialogScaffold(
        actionsInRow: false,
        title: Text(title),
        content: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ) ??
              const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(buttonLabel),
          ),
        ],
      );
    },
  );
}
