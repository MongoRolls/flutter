import 'package:flutter/material.dart';

import '../models/care_record.dart';

/// 关怀足迹时间线条目
class CareTimelineItem extends StatelessWidget {
  final CareRecord record;

  const CareTimelineItem({super.key, required this.record});

  Color get _dotColor => switch (record.dotType) {
    'pink' => const Color(0xFFFF6B9D),
    'blue' => const Color(0xFF4FC3F7),
    'purple' => const Color(0xFFAB47BC),
    _ => const Color(0xFF90A4AE),
  };

  List<Color> get _dotGradient => switch (record.dotType) {
    'pink' => [const Color(0xFFFF6B9D), const Color(0xFFFF8A65)],
    'blue' => [const Color(0xFF4FC3F7), const Color(0xFF0288D1)],
    'purple' => [const Color(0xFFAB47BC), const Color(0xFF7E57C2)],
    _ => [const Color(0xFF90A4AE), const Color(0xFF78909C)],
  };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间线竖线 + 圆点
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _dotGradient,
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _dotColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _dotColor.withValues(alpha: 0.3),
                          _dotColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // 内容卡
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        record.directionLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF455A64),
                        ),
                      ),
                      Text(
                        record.formattedTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB0BEC5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '「${record.message}」',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A2E),
                      height: 1.5,
                    ),
                  ),
                  if (record.isReplied && record.replyText != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${record.toLabel == '你' ? '你' : record.toLabel}回复：${record.replyText}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF66BB6A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
