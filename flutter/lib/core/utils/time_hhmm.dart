import 'package:flutter/material.dart';

/// 将 `HH:mm` 安全解析为 [TimeOfDay]。
TimeOfDay timeOfDayFromHhMm(String raw) {
  final parts = raw.trim().split(':');
  if (parts.length >= 2) {
    final h = int.tryParse(parts[0].trim()) ?? 7;
    final m = int.tryParse(parts[1].trim()) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }
  return const TimeOfDay(hour: 7, minute: 0);
}
