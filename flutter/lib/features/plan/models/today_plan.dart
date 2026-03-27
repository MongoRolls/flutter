import 'dart:convert';

import 'package:hive/hive.dart';

part 'today_plan.g.dart';

@HiveType(typeId: 3)
class TodayPlan extends HiveObject {
  @HiveField(0)
  final String date; // 'yyyy-MM-dd'

  @HiveField(1)
  final String summary; // AI 文字总结

  @HiveField(2)
  final int totalMl; // AI 建议总量

  @HiveField(3)
  final String slotsJson; // JSON array of PlanTimeSlot

  @HiveField(4)
  final String activityType; // 生成时的活动类型

  @HiveField(5)
  final double? temperature; // 生成时的温度（℃）

  @HiveField(6)
  final String? cityName; // 生成时的城市

  @HiveField(7)
  final String createdAt; // ISO 8601 时间戳

  @HiveField(8)
  final String completedSlotsJson; // 已完成的 slot 时间列表 ['07:30','09:00',...]

  List<PlanTimeSlot>? _cachedSlots;
  List<String>? _cachedCompletedSlots;

  TodayPlan({
    required this.date,
    required this.summary,
    required this.totalMl,
    required this.slotsJson,
    required this.activityType,
    this.temperature,
    this.cityName,
    required this.createdAt,
    this.completedSlotsJson = '[]',
  });

  List<PlanTimeSlot> get slots =>
      _cachedSlots ??= (jsonDecode(slotsJson) as List)
          .map((e) => PlanTimeSlot.fromMap(e as Map<String, dynamic>))
          .toList();

  List<String> get completedSlots => _cachedCompletedSlots ??=
      List<String>.from(jsonDecode(completedSlotsJson) as List);

  TodayPlan copyWithCompleted(List<String> newCompleted) => TodayPlan(
    date: date,
    summary: summary,
    totalMl: totalMl,
    slotsJson: slotsJson,
    activityType: activityType,
    temperature: temperature,
    cityName: cityName,
    createdAt: createdAt,
    completedSlotsJson: jsonEncode(newCompleted),
  );
}

/// 不是 Hive 类，只是 Dart 数据类（嵌套序列化为 JSON 字符串）
class PlanTimeSlot {
  final String time; // 'HH:mm'
  final int ml;
  final String note;

  const PlanTimeSlot({
    required this.time,
    required this.ml,
    required this.note,
  });

  factory PlanTimeSlot.fromMap(Map<String, dynamic> m) => PlanTimeSlot(
    time: m['time'] as String,
    ml: m['ml'] as int,
    note: m['note'] as String,
  );

  Map<String, dynamic> toMap() => {'time': time, 'ml': ml, 'note': note};
}
