import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 与官网 `GlassCard`（light）意图一致：大圆角、浅阴影、`border-white/60` 等价边。
/// 不使用大面积 `BackdropFilter`，避免掉帧；与结构化需求中的性能降级策略一致。
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
