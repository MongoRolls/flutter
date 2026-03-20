import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/models/weather_data.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/weather_service.dart';
import '../../chat/services/ai_config.dart';
import '../../chat/services/ai_service.dart';
import '../models/today_plan.dart';
import '../utils/plan_prompt_builder.dart';

enum PlanStatus {
  idle,
  loadingPlan,
  hasPlan,
  inputReady,
  loadingWeather,
  generating,
  parseError,
  weatherError,
}

/// 中间解析对象（流转换后）
class _TodayPlanParsed {
  final String summary;
  final int totalMl;
  final List<PlanTimeSlot> slots;

  _TodayPlanParsed({
    required this.summary,
    required this.totalMl,
    required this.slots,
  });

  factory _TodayPlanParsed.fromMap(Map<String, dynamic> m) {
    final rawSlots = m['slots'] as List? ?? [];
    return _TodayPlanParsed(
      summary: m['summary'] as String? ?? '',
      totalMl: (m['totalMl'] as num?)?.toInt() ?? 2000,
      slots: rawSlots
          .map((e) => PlanTimeSlot.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlanProvider extends ChangeNotifier {
  final UserProvider _userProvider;

  PlanStatus status = PlanStatus.idle;

  // ── 输入 ──
  String activityType = '久坐'; // 久坐/步行/中等运动/高强度运动
  String note = '';
  String wakeTimeOverride = ''; // 空表示使用 profile.wakeTime

  // ── 天气 ──
  WeatherData? weather;
  String? cityName;
  String cityInput = ''; // 手动城市输入框的值

  // ── 生成流式 ──
  String streamingText = ''; // SSE 流中间状态，用于 UI 打字效果

  // ── 结果 ──
  TodayPlan? todayPlan;
  String? errorMessage;

  // ── 面板状态 ──
  bool isInputExpanded = true; // 有计划时，输入区默认折叠

  PlanProvider({required UserProvider userProvider})
    : _userProvider = userProvider;

  void setWakeTimeOverride(String value) {
    wakeTimeOverride = value;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // 加载今日计划
  // ─────────────────────────────────────────────────────────

  Future<void> loadTodayPlan() async {
    status = PlanStatus.loadingPlan;
    notifyListeners();

    final box = Hive.box<TodayPlan>('today_plans');
    final today = _todayKey();
    final plan = box.get(today);

    if (plan != null) {
      todayPlan = plan;
      isInputExpanded = false;
      status = PlanStatus.hasPlan;
      notifyListeners();
      return;
    }

    // 无计划 → 拉取天气
    await loadWeatherByGps();
  }

  // ─────────────────────────────────────────────────────────
  // 天气加载
  // ─────────────────────────────────────────────────────────

  Future<void> loadWeatherByGps() async {
    status = PlanStatus.loadingWeather;
    notifyListeners();
    try {
      final loc = await LocationService.instance.getCurrentLocation();
      weather = await WeatherService.instance.getWeather(loc.lat, loc.lon);
      if (loc.isDefault) {
        cityName = '北京';
      }
      status = PlanStatus.inputReady;
    } catch (e) {
      status = PlanStatus.weatherError;
      errorMessage = '定位失败，请手动输入城市名';
    }
    notifyListeners();
  }

  Future<void> loadWeatherByCity(String city) async {
    status = PlanStatus.loadingWeather;
    cityInput = city;
    notifyListeners();
    try {
      // 调用 WeatherService geocoding 接口
      final coords = await WeatherService.instance.geocodeCity(city);
      weather = await WeatherService.instance.getWeather(
        coords.lat,
        coords.lon,
      );
      cityName = city;
      status = PlanStatus.inputReady;
    } catch (e) {
      status = PlanStatus.weatherError;
      errorMessage = '找不到城市"$city"，请重新输入';
    }
    notifyListeners();
  }

  void retryWeather() {
    errorMessage = null;
    loadWeatherByGps();
  }

  // ─────────────────────────────────────────────────────────
  // AI 生成（流式 SSE + JSON 解析）
  // ─────────────────────────────────────────────────────────

  Future<void> generatePlan() async {
    status = PlanStatus.generating;
    streamingText = '';
    errorMessage = null;
    notifyListeners();

    try {
      final config = await AiConfig.load();
      final service = AiService(config: config);
      final prompt = PlanPromptBuilder.build(
        userProvider: _userProvider,
        weather: weather,
        cityName: cityName,
        activityType: activityType,
        note: note,
        wakeTime: wakeTimeOverride.isEmpty
            ? _userProvider.profile.wakeTime
            : wakeTimeOverride,
      );

      final messages = [
        {'role': 'system', 'content': PlanPromptBuilder.systemPrompt},
        {'role': 'user', 'content': prompt},
      ];

      // 流式累积
      await for (final event in service.sendMessageStream(
        messages: messages,
        tools: [],
      )) {
        if (event is AiTextDelta) {
          streamingText += event.text;
          notifyListeners(); // 触发打字效果
        } else if (event is AiError) {
          status = PlanStatus.parseError;
          errorMessage = 'AI 请求失败：${event.message}';
          notifyListeners();
          service.dispose();
          return;
        }
      }

      service.dispose();

      // 流结束后解析 JSON
      final parsed = _parseJson(streamingText);
      if (parsed == null) {
        status = PlanStatus.parseError;
        errorMessage = 'AI 返回格式异常，请重试';
        notifyListeners();
        return;
      }

      // 持久化到 Hive
      final today = _todayKey();
      final todayPlanObj = TodayPlan(
        date: today,
        summary: parsed.summary,
        totalMl: parsed.totalMl,
        slotsJson: jsonEncode(parsed.slots.map((s) => s.toMap()).toList()),
        activityType: activityType,
        temperature: weather?.temperature,
        cityName: cityName,
        createdAt: DateTime.now().toIso8601String(),
      );
      await Hive.box<TodayPlan>('today_plans').put(today, todayPlanObj);

      todayPlan = todayPlanObj;
      isInputExpanded = false;
      status = PlanStatus.hasPlan;
      notifyListeners();
    } catch (e) {
      status = PlanStatus.parseError;
      errorMessage = '生成失败：$e';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  // 时间槽记录饮水
  // ─────────────────────────────────────────────────────────

  Future<void> logSlotDrink(PlanTimeSlot slot) async {
    if (todayPlan == null) return;

    // 1. 记录到 UserProvider（驱动首页进度更新）
    await _userProvider.addDrink(slot.ml, type: '💧', desc: slot.note);

    // 2. 标记此 slot 为已记录
    final completed = List<String>.from(todayPlan!.completedSlots);
    if (!completed.contains(slot.time)) {
      completed.add(slot.time);
      final updated = todayPlan!.copyWithCompleted(completed);
      await Hive.box<TodayPlan>('today_plans').put(updated.date, updated);
      todayPlan = updated;
      notifyListeners();
    }
  }

  /// 取消标记（不回撤 addDrink，只清除完成标记）
  Future<void> unlogSlot(String slotTime) async {
    if (todayPlan == null) return;
    final completed = List<String>.from(todayPlan!.completedSlots)
      ..remove(slotTime);
    final updated = todayPlan!.copyWithCompleted(completed);
    await Hive.box<TodayPlan>('today_plans').put(updated.date, updated);
    todayPlan = updated;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // 集成动作
  // ─────────────────────────────────────────────────────────

  /// 采纳为每日目标（更新 UserProvider）
  Future<void> adoptAsGoal() async {
    if (todayPlan == null) return;
    _userProvider.profile.dailyGoalMl = todayPlan!.totalMl;
    await _userProvider.saveProfile();
    notifyListeners();
  }

  /// 同步今日计划提醒（覆盖式），返回已安排数量
  Future<int> scheduleSlotReminders() async {
    if (todayPlan == null) return 0;

    // 1. 取消 ID 范围 1000-1999 的计划提醒
    await NotificationService.instance.cancelPlanReminders();

    // 2. 只为未来时间点安排通知
    final now = DateTime.now();
    int scheduled = 0;
    final slots = todayPlan!.slots;
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final parts = slot.time.split(':');
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (dt.isAfter(now)) {
        await NotificationService.instance.scheduleCustomReminder(
          title: '${slot.note}（${slot.ml}ml）',
          scheduledDate: dt,
          repeat: 'none',
          id: 1000 + i,
        );
        scheduled++;
      }
    }
    return scheduled;
  }

  /// 折叠/展开计划参数面板（供 UI 调用）
  void setInputExpanded(bool expanded) {
    isInputExpanded = expanded;
    notifyListeners();
  }

  /// 选择今日主要活动类型
  void setActivityType(String type) {
    activityType = type;
    notifyListeners();
  }

  /// 清空当日计划，重新生成
  void reset() {
    final today = _todayKey();
    Hive.box<TodayPlan>('today_plans').delete(today);
    todayPlan = null;
    streamingText = '';
    errorMessage = null;
    isInputExpanded = true;
    status = PlanStatus.inputReady;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // 私有工具
  // ─────────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// JSON 解析容错：提取最外层 {...} 块
  _TodayPlanParsed? _parseJson(String raw) {
    // 尝试剥离 ```json ... ``` 代码块
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final codeMatch = codeBlockRegex.firstMatch(raw);
    final candidate = codeMatch != null ? codeMatch.group(1)! : raw;

    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    try {
      final obj =
          jsonDecode(candidate.substring(start, end + 1))
              as Map<String, dynamic>;
      return _TodayPlanParsed.fromMap(obj);
    } catch (_) {
      return null;
    }
  }
}
