import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 居中模态对话框的圆角（与 `design-tokens.md` 模态层一致，写死为 `AppRadius.x2l`）。
double get appDialogBorderRadius => AppRadius.x2l;

/// 水平方向最大宽度：`min(400, 屏宽 − 48)`（逻辑像素）。
double appDialogMaxWidth(double screenWidth) =>
    math.min(400.0, screenWidth - 48);

/// 纯色卡片外壳，供确认/告知及自定义表单对话框复用（非毛玻璃）。
class AppDialogScaffold extends StatelessWidget {
  const AppDialogScaffold({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.insetPadding,
    this.actionsInRow = true,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  /// 为 `false` 时操作区纵向排布（如单按钮全宽）。
  final bool actionsInRow;

  /// 覆盖默认 inset（例如键盘顶起时与 [AlertDialog] 行为对齐）。
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxW = appDialogMaxWidth(width);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final padding = insetPadding ??
        EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(appDialogBorderRadius),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ) ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                  child: title,
                ),
                const SizedBox(height: 12),
                DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ) ??
                      const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                  child: content,
                ),
                const SizedBox(height: 16),
                if (actionsInRow)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _spacedActions(actions),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actions,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _spacedActions(List<Widget> actions) {
    if (actions.isEmpty) return actions;
    final out = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) out.add(const SizedBox(width: 8));
      out.add(actions[i]);
    }
    return out;
  }
}
