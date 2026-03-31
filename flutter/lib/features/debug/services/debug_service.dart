import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/backend_api_service.dart';
import '../../../core/services/drink_sync_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/community/providers/heart_provider.dart';
import '../../../features/plan/models/today_plan.dart';

enum TestStatus { success, failure, info }

class TestResult {
  final TestStatus status;
  final String label;
  final String message;
  final String? detail;
  final DateTime timestamp;

  const TestResult({
    required this.status,
    required this.label,
    required this.message,
    this.detail,
    required this.timestamp,
  });

  String get statusIcon => switch (status) {
    TestStatus.success => '✅',
    TestStatus.failure => '❌',
    TestStatus.info => 'ℹ️',
  };

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}

class DebugService {
  DebugService._();
  static final DebugService instance = DebugService._();

  // ============ Notifications ============

  Future<TestResult> checkNotificationPermission() async {
    try {
      final granted = await NotificationService.instance.requestPermission();
      return TestResult(
        status: granted ? TestStatus.success : TestStatus.failure,
        label: '检查通知权限',
        message: granted ? '通知权限已授权' : '通知权限未授权',
        detail: granted ? '可以正常发送通知' : '请在系统设置中开启通知权限',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '检查通知权限',
        message: '检查权限失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> showImmediateTestNotification(String style) async {
    try {
      await NotificationService.instance.showTestNotification(
        reminderStyle: style,
      );
      return TestResult(
        status: TestStatus.success,
        label: '触发即时通知',
        message: '已发送测试通知 ($style)',
        detail: '请查看系统通知栏。使用智能手表时，需先在系统或穿戴 App 中允许通知同步到手表后，表端才会显示。',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '触发即时通知',
        message: '发送通知失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> scheduleTestReminders(UserProfile profile) async {
    try {
      await NotificationService.instance.scheduleReminders(
        wakeTime: profile.wakeTime,
        bedTime: profile.bedTime,
        intervalMin: profile.reminderIntervalMin,
        reminderStyle: profile.reminderStyle,
      );
      return TestResult(
        status: TestStatus.success,
        label: '调度提醒(7天)',
        message: '已调度7天提醒通知',
        detail:
            '时间范围: ${profile.wakeTime} ~ ${profile.bedTime}\n间隔: ${profile.reminderIntervalMin}分钟\n风格: ${profile.reminderStyle}',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '调度提醒(7天)',
        message: '调度失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> cancelAllNotifications() async {
    try {
      await NotificationService.instance.cancelAll();
      return TestResult(
        status: TestStatus.success,
        label: '取消全部通知',
        message: '已取消所有调度通知',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '取消全部通知',
        message: '取消失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  // ============ Provider State ============

  TestResult inspectProviderState(UserProvider provider) {
    try {
      final state = {
        'profile': {
          'nickname': provider.profile.nickname,
          'weight': provider.profile.weight,
          'dailyGoalMl': provider.profile.dailyGoalMl,
          'wakeTime': provider.profile.wakeTime,
          'bedTime': provider.profile.bedTime,
          'reminderIntervalMin': provider.profile.reminderIntervalMin,
          'reminderStyle': provider.profile.reminderStyle,
          'notificationsEnabled': provider.profile.notificationsEnabled,
          'onboardingCompleted': provider.profile.onboardingCompleted,
        },
        'todayMl': provider.todayMl,
        'progress': provider.progress,
        'remainingMl': provider.remainingMl,
        'streakDays': provider.streakDays,
        'logsCount': provider.logs.length,
        'logs': provider.logs
            .map((l) => {'time': l.time, 'ml': l.ml, 'icon': l.icon})
            .toList(),
        'monthlyHits': provider.monthlyHits.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
      };
      return TestResult(
        status: TestStatus.success,
        label: '查看当前状态',
        message: 'Provider状态正常',
        detail: const JsonEncoder.withIndent('  ').convert(state),
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '查看当前状态',
        message: '获取状态失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  // ============ Community / care contacts ============

  /// `GET /api/care/peers/hydration` 原始 JSON（用于排查好友今日毫升不同步）
  Future<TestResult> inspectPeersHydrationRaw() async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) {
      return TestResult(
        status: TestStatus.info,
        label: 'Peers hydration 原始响应',
        message: '未登录后端，跳过请求',
        timestamp: DateTime.now(),
      );
    }
    try {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final rows = await backend.getPeersHydration(
        date: date,
        tzOffset: now.timeZoneOffset.inMinutes,
      );
      return TestResult(
        status: TestStatus.success,
        label: 'Peers hydration 原始响应',
        message: '共 ${rows.length} 条',
        detail: const JsonEncoder.withIndent('  ').convert(rows),
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: 'Peers hydration 原始响应',
        message: '请求失败',
        detail: _dioDebugDetail(e, st),
        timestamp: DateTime.now(),
      );
    }
  }

  /// `GET /api/care/contacts` 原始 JSON（排查心连心列表为空 / 字段不符）
  Future<TestResult> inspectCareContactsRaw() async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) {
      return TestResult(
        status: TestStatus.info,
        label: 'Care contacts 原始响应',
        message: '未登录后端，跳过请求',
        timestamp: DateTime.now(),
      );
    }
    try {
      final list = await backend.getCareContacts();
      return TestResult(
        status: TestStatus.success,
        label: 'Care contacts 原始响应',
        message: '共 ${list.length} 条',
        detail: const JsonEncoder.withIndent('  ').convert(list),
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: 'Care contacts 原始响应',
        message: '请求失败',
        detail: _dioDebugDetail(e, st),
        timestamp: DateTime.now(),
      );
    }
  }

  String _dioDebugDetail(Object e, StackTrace st) {
    if (e is DioException) {
      final buf = StringBuffer('$e\n');
      buf.writeln('status=${e.response?.statusCode}');
      buf.writeln('data=${e.response?.data}');
      buf.writeln(st);
      return buf.toString();
    }
    return '$e\n$st';
  }

  TestResult inspectHeartContactsState(HeartProvider heart) {
    try {
      final contacts = heart.contacts;
      final lines = contacts
          .map(
            (c) =>
                '${c.id}: ${c.name} today=${c.mockTodayMl}ml goal=${c.mockDailyGoalMl}ml '
                'hydrationVisible=${c.hydrationVisible}',
          )
          .join('\n');
      return TestResult(
        status: TestStatus.success,
        label: '社区好友缓存',
        message: '${contacts.length} 个联系人',
        detail: lines.isEmpty ? '(空)' : lines,
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '社区好友缓存',
        message: '读取失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> refreshHeartPeersHydration(HeartProvider heart) async {
    try {
      final ok = await heart.refreshPeersHydration();
      return TestResult(
        status: ok ? TestStatus.success : TestStatus.failure,
        label: '刷新好友饮水摘要',
        message: ok ? '已合并；成功时写入缓存' : '拉取失败（未覆写毫升缓存）',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '刷新好友饮水摘要',
        message: '异常',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> addTestDrink(UserProvider provider) async {
    try {
      await provider.addDrink(250, type: '🧪', desc: '测试饮水');
      return TestResult(
        status: TestStatus.success,
        label: '添加测试饮水',
        message: '已添加 250ml 测试饮水',
        detail: '当前总计: ${provider.todayMl}ml',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '添加测试饮水',
        message: '添加失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> resetTodayIntake(UserProvider provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      await prefs.setInt('today_ml', 0);
      await prefs.setString('today_logs', '[]');
      await prefs.setString('today_date', today);
      // 重新加载provider
      await provider.loadProfile();
      return TestResult(
        status: TestStatus.success,
        label: '清空今日饮水',
        message: '今日饮水数据已清空',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '清空今日饮水',
        message: '清空失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  // ============ Persistence ============

  Future<TestResult> dumpAllPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final data = <String, dynamic>{};
      for (final key in keys) {
        data[key] = prefs.get(key);
      }
      return TestResult(
        status: TestStatus.success,
        label: '导出全部SharedPrefs',
        message: '共 ${keys.length} 个键值',
        detail: const JsonEncoder.withIndent('  ').convert(data),
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '导出全部SharedPrefs',
        message: '导出失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> clearTodayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('today_ml');
      await prefs.remove('today_logs');
      await prefs.remove('today_date');
      return TestResult(
        status: TestStatus.success,
        label: '清空今日数据',
        message: '今日数据已清除',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '清空今日数据',
        message: '清除失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> clearAllData(UserProvider provider) async {
    try {
      // 1. 清空 SharedPreferences（用户档案、饮水记录、历史等）
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 2. 清空 Hive：健康档案（memory_facts）
      if (Hive.isBoxOpen('memory_facts')) {
        await Hive.box('memory_facts').clear();
      } else {
        final box = await Hive.openBox('memory_facts');
        await box.clear();
      }

      // 3. 清空 Hive：会话摘要（session_summaries）
      if (Hive.isBoxOpen('session_summaries')) {
        await Hive.box('session_summaries').clear();
      } else {
        final box = await Hive.openBox('session_summaries');
        await box.clear();
      }

      // 4. 清空 Hive：自定义提醒（custom_reminders）
      if (Hive.isBoxOpen('custom_reminders')) {
        await Hive.box('custom_reminders').clear();
      } else {
        try {
          final box = await Hive.openBox('custom_reminders');
          await box.clear();
        } catch (_) {}
      }

      // 5. 清空 Hive：今日计划（today_plans）
      if (Hive.isBoxOpen('today_plans')) {
        await Hive.box<TodayPlan>('today_plans').clear();
      } else {
        final box = await Hive.openBox<TodayPlan>('today_plans');
        await box.clear();
      }

      // 6. 取消所有通知
      await NotificationService.instance.cancelAll();

      // 7. 后端单例内存与磁盘一致（prefs 已 clear，否则仍持有旧 JWT）
      await BackendApiService.instance.resetLocalAuthState();
      DrinkSyncService.instance.resetInMemoryCounters();

      // 8. 冷启动外不会再次执行 main 里的 ensureAuthenticated — 这里重新 deviceLogin
      try {
        await BackendApiService.instance.ensureAuthenticated();
      } catch (e) {
        debugPrint('Debug clearAllData: ensureAuthenticated failed: $e');
      }

      // 9. 重置 provider 内存状态
      provider.updateProfile(UserProfile());

      return TestResult(
        status: TestStatus.success,
        label: '重置全部数据',
        message: '所有数据已完全清除，即将返回引导页',
        detail: '已清空：用户档案、饮水记录、历史归档、健康档案、会话摘要、今日计划、自定义提醒、通知；已重置后端会话并尝试重新登录',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '重置全部数据',
        message: '重置失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  // ============ Sync Debug ============

  Map<String, dynamic> getSyncStatus() {
    final syncService = DrinkSyncService.instance;
    return {
      'lastSyncAt': syncService.lastSyncAt?.toIso8601String(),
      'pendingCount': syncService.pendingSyncCount,
      'failedCount': syncService.failedCount,
      'isAuthenticated': BackendApiService.instance.isAuthenticated,
      'deviceId': BackendApiService.instance.deviceId,
    };
  }

  Future<TestResult> triggerManualSync(UserProvider provider) async {
    try {
      final syncService = DrinkSyncService.instance;

      // 1. 同步待同步队列
      final queueResult = await syncService.syncPendingQueue();

      // 2. 拉取当月数据
      await syncService.syncMonthlyLogs();

      // 3. 刷新本地状态
      await provider.loadProfile();

      return TestResult(
        status: queueResult == SyncResult.success
            ? TestStatus.success
            : TestStatus.info,
        label: '手动同步',
        message: '同步完成: ${queueResult.name}',
        detail:
            '待同步: ${syncService.pendingSyncCount}, 失败: ${syncService.failedCount}',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '手动同步',
        message: '同步失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> inspectPendingQueue() async {
    try {
      final status = getSyncStatus();

      return TestResult(
        status: TestStatus.info,
        label: '查看同步队列',
        message: '待同步: ${status['pendingCount']}, 失败: ${status['failedCount']}',
        detail: const JsonEncoder.withIndent('  ').convert(status),
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '查看同步队列',
        message: '获取失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<TestResult> clearFailedQueue() async {
    try {
      await DrinkSyncService.instance.clearFailedQueue();

      return TestResult(
        status: TestStatus.success,
        label: '清空失败队列',
        message: '失败队列已清空',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '清空失败队列',
        message: '清空失败',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  // ============ Platform Info ============

  /// 注入当月 Mock 饮水数据，用于预览首页统计图表效果。
  ///
  /// 生成策略：
  /// - 当月 1 号至昨日，随机分布高/中/低/零摄入天
  /// - 今日注入适量未达标数据（方便看「未达标」柱）
  /// - 保留历史 history_ 键，保证连续天数显示正常
  Future<TestResult> injectMockMonthlyData(UserProvider provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = now.day;
      final goal = provider.profile.dailyGoalMl;

      // ── 生成本月每日数据 ──────────────────────────────────────
      // 模拟一个真实用户的喝水节律：大部分天达标，偶尔懈怠
      final mockPattern = <int, int>{};

      // 达标/高摄入的天（目标 × 100%~130%）
      final goodDays = [1, 2, 4, 6, 7, 9, 11, 12, 14, 16, 17, 19, 21, 22];
      // 未达标但有摄入（目标 × 50%~90%）
      final slackDays = [3, 8, 13, 18, 23];
      // 完全忘记喝水（0ml，不写入 map）
      final zeroDays = [5, 10, 15, 20, 24];

      for (var d = 1; d < today; d++) {
        if (zeroDays.contains(d)) continue; // 不写 = 0ml
        final int ml;
        if (goodDays.contains(d)) {
          // 达标：目标量的 100%～130%，加些随机感
          final factor = 1.0 + (d % 7) * 0.04; // 1.00~1.24
          ml = (goal * factor).round();
        } else if (slackDays.contains(d)) {
          // 未达标：目标量的 55%～85%
          final factor = 0.55 + (d % 5) * 0.06; // 0.55~0.79
          ml = (goal * factor).round();
        } else {
          // 默认：正常达标
          ml = (goal * (0.95 + (d % 3) * 0.05)).round();
        }
        mockPattern[d] = ml;

        // 同步写 history_ 键（连续天数计算依赖）
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        await prefs.setInt('history_$dateStr', ml);
      }

      // 今日：注入约 60% 目标量（未达标，方便看灰柱）
      final todayMl = (goal * 0.6).round();
      mockPattern[today] = todayMl;

      // ── 写入 SharedPreferences ───────────────────────────────
      final monthKey = 'monthly_hits_${now.year}_${now.month}';
      final monthMap = mockPattern.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(monthKey, jsonEncode(monthMap));

      // 今日数据
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString('today_date', todayDateStr);
      await prefs.setInt('today_ml', todayMl);
      await prefs.setString(
        'today_logs',
        jsonEncode([
          {'time': '07:30', 'icon': '💧', 'description': '起床喝水', 'ml': 300},
          {
            'time': '10:00',
            'icon': '🍵',
            'description': '上午茶',
            'ml': (goal * 0.15).round(),
          },
          {
            'time': '13:30',
            'icon': '💧',
            'description': '午饭后',
            'ml': (goal * 0.22).round(),
          },
          {
            'time': '16:00',
            'icon': '🧃',
            'description': '下午果汁',
            'ml': todayMl - 300 - (goal * 0.15).round() - (goal * 0.22).round(),
          },
        ]),
      );

      // 重载 provider
      await provider.loadProfile();

      final achievedCount = mockPattern.entries
          .where((e) => e.value >= goal)
          .length;
      return TestResult(
        status: TestStatus.success,
        label: '注入 Mock 月度数据',
        message: '已写入 ${mockPattern.length} 天数据，其中 $achievedCount 天达标',
        detail:
            '目标: ${goal}ml | 今日: ${todayMl}ml\n'
            'key: $monthKey\n'
            '数据预览: ${const JsonEncoder.withIndent('  ').convert(monthMap)}',
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '注入 Mock 月度数据',
        message: '注入失败: $e',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  /// 一键写入「正常演示用户」档案 + 本月/今日饮水 Mock（适合联调首页、日历、同步）。
  Future<TestResult> injectFullDemoTestData(UserProvider provider) async {
    try {
      provider.updateProfile(
        UserProfile(
          nickname: '演示用户',
          gender: '女',
          activityLevel: '中等',
          weight: 58,
          dailyGoalMl: 2000,
          wakeTime: '07:30',
          bedTime: '23:00',
          reminderIntervalMin: 60,
          reminderStyle: '温柔',
          notificationsEnabled: true,
          onboardingCompleted: true,
        ),
      );
      final inner = await injectMockMonthlyData(provider);
      return TestResult(
        status: inner.status,
        label: '插入完整测试数据',
        message:
            '已写入演示档案（目标 2000ml、已完成引导）并注入本月与今日饮水；'
            '${inner.message}',
        detail: inner.detail,
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      return TestResult(
        status: TestStatus.failure,
        label: '插入完整测试数据',
        message: '注入失败: $e',
        detail: '$e\n$st',
        timestamp: DateTime.now(),
      );
    }
  }

  // ============ Platform Info ============

  Map<String, String> get platformInfo => {
    'platform': defaultTargetPlatform.name,
    'isWeb': kIsWeb.toString(),
    'isAndroid': (defaultTargetPlatform == TargetPlatform.android).toString(),
    'isIOS': (defaultTargetPlatform == TargetPlatform.iOS).toString(),
    'isMacOS': (defaultTargetPlatform == TargetPlatform.macOS).toString(),
    'isWindows': (defaultTargetPlatform == TargetPlatform.windows).toString(),
    'isLinux': (defaultTargetPlatform == TargetPlatform.linux).toString(),
    'dartVersion': defaultTargetPlatform.name,
  };
}
