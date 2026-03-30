import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 底部模态面板顶角圆角（与 `design-tokens.md` 一致，取 `AppRadius.x2l`）。
BorderRadius get appModalSheetTopRadius => const BorderRadius.vertical(
      top: Radius.circular(AppRadius.x2l),
    );

/// 标准底部面板：纯色 `bgCard`、顶角圆角、可选拖动条、`SafeArea` 底部留白。
///
/// [builder] 返回面板主体（标题、列表等）；外层已处理水平 padding 与底部安全区。
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: AppColors.bgCard,
    shape: RoundedRectangleBorder(borderRadius: appModalSheetTopRadius),
    builder: (ctx) {
      final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) const _ModalDragHandle(),
              builder(ctx),
            ],
          ),
        ),
      );
    },
  );
}

class _ModalDragHandle extends StatelessWidget {
  const _ModalDragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
