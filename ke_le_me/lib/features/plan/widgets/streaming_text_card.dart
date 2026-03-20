import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../common/widgets/glass_card.dart';

/// 健康小贴士列表
const _healthTips = [
  '💡 早上起床后喝一杯温水，能帮助唤醒身体代谢',
  '💡 运动前30分钟补水200-300ml，效果更好',
  '💡 少量多次饮水比一次性大量饮水更健康',
  '💡 感到口渴时身体已经缺水2%，定时补水很重要',
  '💡 高温天气下每小时需额外补充150-250ml水分',
  '💡 睡前1小时少量饮水，避免夜间起夜影响睡眠',
  '💡 咖啡和茶有利尿作用，饮用后记得多补充水分',
  '💡 饭前30分钟饮水有助于消化，饭中不宜大量饮水',
  '💡 空调环境中身体水分流失加快，更需注意补水',
];

class StreamingTextCard extends StatefulWidget {
  final String text;

  const StreamingTextCard({super.key, required this.text});

  @override
  State<StreamingTextCard> createState() => _StreamingTextCardState();
}

class _StreamingTextCardState extends State<StreamingTextCard>
    with TickerProviderStateMixin {
  late final AnimationController _dotController;
  late final AnimationController _fadeController;
  Timer? _tipTimer;
  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();

    // 三个跳动圆点动画
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // 贴士文字淡入淡出
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );

    // 每4秒切换一条贴士
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _switchTip();
    });
  }

  void _switchTip() async {
    await _fadeController.reverse(); // 淡出
    if (!mounted) return;
    setState(() {
      _currentTipIndex = (_currentTipIndex + 1) % _healthTips.length;
    });
    _fadeController.forward(); // 淡入
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _dotController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.blue,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AI 正在生成计划',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 中央 loading 动画（三个跳动圆点）
          Center(
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.2;
                  final t = ((_dotController.value - delay) % 1.0).clamp(
                    0.0,
                    1.0,
                  );
                  final bounce = (t < 0.5) ? (t * 2.0) : (2.0 - t * 2.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Transform.translate(
                      offset: Offset(0, -6 * bounce),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(
                            alpha: 0.4 + 0.6 * bounce,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 健康小贴士（淡入淡出轮播）
          FadeTransition(
            opacity: _fadeController,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSection,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _healthTips[_currentTipIndex],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 底部提示
          const Center(
            child: Text(
              '正在根据你的情况定制专属饮水计划...',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
