import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog.dart';

/// 标准居中确认框：双按钮，返回 `Future<bool?>`（确认 / 取消 / 遮罩关闭）。
///
/// [isDestructive] 为 true 时主按钮为红底白字；否则为 [ElevatedButton] 主题蓝。
/// [confirmButtonStyle] 非空时覆盖主按钮样式（用于非 destructive 但需强调色等场景）。
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = '取消',
  String confirmLabel = '确认',
  bool isDestructive = false,
  bool barrierDismissible = true,
  ButtonStyle? confirmButtonStyle,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return AppDialogScaffold(
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (confirmButtonStyle != null)
            ElevatedButton(
              style: confirmButtonStyle,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            )
          else if (isDestructive)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
        ],
      );
    },
  );
}
