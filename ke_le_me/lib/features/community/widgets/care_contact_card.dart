import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/care_contact.dart';
import 'water_ring_mini.dart';

/// 联系人关怀卡片（完整按 HTML 稿实现）
class CareContactCard extends StatefulWidget {
  final CareContact contact;
  final VoidCallback onRemind;

  const CareContactCard({
    super.key,
    required this.contact,
    required this.onRemind,
  });

  @override
  State<CareContactCard> createState() => _CareContactCardState();
}

class _CareContactCardState extends State<CareContactCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _justReminded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// 头像渐变色映射
  List<Color> get _avatarGradient => switch (widget.contact.relationship) {
    'mom' => [AppColors.pinkLight, const Color(0xFFF06292)],
    'dad' => [const Color(0xFF64B5F6), const Color(0xFF42A5F5)],
    'partner' => [const Color(0xFFFF8A65), const Color(0xFFFF7043)],
    _ => [const Color(0xFF81C784), AppColors.greenSoft],
  };

  /// 状态指示点颜色
  Color get _statusColor => switch (widget.contact.status) {
    'done' => AppColors.greenSoft,
    'inProgress' => AppColors.orangeWarm,
    _ => AppColors.red,
  };

  /// 饮水状态文案
  Widget get _statusText {
    final c = widget.contact;
    if (c.status == 'done') {
      return Text.rich(
        TextSpan(
          text: '今日 ',
          children: [
            TextSpan(
              text: '✓ 已喝 ${c.mockTodayMl}ml',
              style: const TextStyle(color: AppColors.greenSoft),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
      );
    } else if (c.status == 'inProgress') {
      return Text.rich(
        TextSpan(
          text: '今日 ',
          children: [
            TextSpan(
              text: '⚠ 仅喝了 ${c.mockTodayMl}ml',
              style: const TextStyle(color: AppColors.orangeWarm),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
      );
    }
    return const Text.rich(
      TextSpan(
        text: '今日 ',
        children: [
          TextSpan(
            text: '⚠ 还没开始喝',
            style: TextStyle(color: AppColors.orangeWarm),
          ),
        ],
      ),
      style: TextStyle(fontSize: 11, color: AppColors.textHint),
    );
  }

  /// 操作按钮
  String get _buttonText {
    if (_justReminded) return '✓ 已提醒';
    if (widget.contact.progress >= 0.8) return '发送爱心';
    return '提醒喝水';
  }

  bool get _shouldPulse => !_justReminded && widget.contact.progress < 0.5;

  void _handleTap() {
    if (_justReminded) return;
    setState(() => _justReminded = true);
    widget.onRemind();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _justReminded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          // 头像
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
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
                  widget.contact.avatarEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.relationship == 'partner'
                      ? '${widget.contact.name}（${widget.contact.relationshipLabel}）'
                      : widget.contact.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 2),
                _statusText,
              ],
            ),
          ),
          // 右侧：进度环 + 操作按钮
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              WaterRingMini(progress: widget.contact.progress),
              const SizedBox(height: 6),
              _shouldPulse
                  ? AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, child) => Transform.scale(
                        scale: 1.0 + _pulseController.value * 0.08,
                        child: child,
                      ),
                      child: _buildRemindBtn(),
                    )
                  : _buildRemindBtn(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemindBtn() {
    final isReminded = _justReminded;
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: isReminded
              ? const LinearGradient(
                  colors: [AppColors.greenSoft, AppColors.greenDark],
                )
              : null,
          color: isReminded ? null : AppColors.pinkBg,
          borderRadius: BorderRadius.circular(8),
          border: isReminded
              ? null
              : Border.all(color: const Color(0x30FF6B9D)),
        ),
        child: Text(
          _buttonText,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isReminded ? Colors.white : AppColors.redDeep,
          ),
        ),
      ),
    );
  }
}
