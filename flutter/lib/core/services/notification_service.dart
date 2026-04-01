import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/peer_remind_templates.dart';
import 'backend_api_service.dart';

/// 本地通知（喝水 / 自定义 / 心连心等）。
///
/// Android 上各渠道均使用 [Importance.high]，便于系统向已配对的智能手表同步
/// 镜像通知（仍取决于系统与穿戴 App 设置）。请勿改为 `low`/`min`，以免表端被折叠或不同步。
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'keleme_water_reminder';
  static const _channelName = '喝水提醒';
  static const _channelDesc = '定时提醒你喝水';

  /// 在社区 Tab 有队友时写入：本地定时喝水提醒改用 [kPeerRemindBodiesForNotifications]。
  static const waterRemindersUsePeerCopyPrefKey = 'water_reminders_use_peer_copy';

  /// SharedPreferences key：记录已消费的最新好友提醒 ID，避免重复使用同一条。
  static const _consumedCareRemindIdPrefKey = 'consumed_care_remind_id';

  /// 与普通日程喝水提醒分离：好友「心连心」模板提醒（接收端展示用）
  static const _peerCareChannelId = 'keleme_peer_care';
  static const _peerCareChannelName = '心连心好友提醒';
  static const _peerCareChannelDesc = '好友向你发送的喝水提醒';

  static const List<String> _gentleMessages = [
    '该喝水啦，来一杯温水吧 ~',
    '工作辛苦了，记得补充水分哦',
    '休息一下，喝杯水再继续',
    '你的身体需要水分，快去喝一杯吧',
    '今天喝够水了吗？来一杯吧',
  ];

  static const List<String> _livelyMessages = [
    '叮咚！你的水杯在召唤你！',
    '喝水时间到！冲冲冲！',
    '嘿！别忘了你的水杯！',
    '水分补给站上线！快来打卡！',
    '滴滴滴～喝水小闹钟响啦！',
  ];

  static const List<String> _seriousMessages = [
    '距上次饮水已过设定时间，请及时补充水分',
    '请注意：长时间未饮水会影响身体机能',
    '提醒：按时饮水是维持健康的基本要求',
    '您已超过提醒间隔未饮水，请立即补充',
    '健康提示：保持规律饮水习惯至关重要',
  ];

  Future<void> init() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _peerCareChannelId,
          _peerCareChannelName,
          description: _peerCareChannelDesc,
          importance: Importance.high,
        ),
      );
    }
  }

  /// 展示好友发来的心连心提醒（与 [scheduleReminders] 所用渠道不同）。
  /// 远端推送接入后由推送处理器调用；模板正文与 `POST /api/care/remind` 一致。
  Future<void> showPeerCareNotification({
    required String title,
    required String body,
  }) async {
    final id = 9000 + Random().nextInt(100);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _peerCareChannelId,
          _peerCareChannelName,
          channelDescription: _peerCareChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'keleme_peer_care',
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'keleme_peer_care',
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final granted = await macos?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<void> scheduleReminders({
    required String wakeTime,
    required String bedTime,
    required int intervalMin,
    String reminderStyle = '温柔',
    /// 为 null 时读 [SharedPreferences]（社区有队友且进入过社区 Tab 后为 true）。
    bool? usePeerRemindBodies,
  }) async {
    await cancelAll();

    // 间隔为 0 会导致 while 循环无法前进，卡死应用启动（见 main.dart 调度）
    final stepMin = intervalMin <= 0 ? 90 : intervalMin;

    final now = tz.TZDateTime.now(tz.local);
    final wakeParts = wakeTime.split(':');
    final bedParts = bedTime.split(':');
    final wakeHour = int.parse(wakeParts[0]);
    final wakeMinute = int.parse(wakeParts[1]);
    final bedHour = int.parse(bedParts[0]);
    final bedMinute = int.parse(bedParts[1]);

    final prefs = await SharedPreferences.getInstance();

    final usePeer = usePeerRemindBodies ??
        prefs.getBool(waterRemindersUsePeerCopyPrefKey) ??
        false;

    final List<String> messages = usePeer
        ? kPeerRemindBodiesForNotifications
        : switch (reminderStyle) {
            '活泼' => _livelyMessages,
            '严肃' => _seriousMessages,
            _ => _gentleMessages,
          };

    // 通过接口获取最近收到的好友提醒；若 ID 未消费过，首条通知使用该模板文案
    String? peerCareBody;
    String? peerCareRemindId;
    try {
      final remind = await BackendApiService.instance.fetchLatestCareRemind();
      if (remind != null) {
        final remindId = remind['id'] as String?;
        final body = remind['templateBody'] as String?;
        final consumed = prefs.getString(_consumedCareRemindIdPrefKey);
        if (remindId != null && body != null && remindId != consumed) {
          peerCareBody = body;
          peerCareRemindId = remindId;
        }
      }
    } catch (_) {
      // 网络异常时不阻塞通知调度
    }

    final rng = Random();
    var id = 0;

    // 为未来 7 天调度通知
    for (var day = 0; day < 7; day++) {
      final baseDate = now.add(Duration(days: day));
      var current = tz.TZDateTime(
        tz.local,
        baseDate.year,
        baseDate.month,
        baseDate.day,
        wakeHour,
        wakeMinute,
      );

      final bedEnd = tz.TZDateTime(
        tz.local,
        baseDate.year,
        baseDate.month,
        baseDate.day,
        bedHour,
        bedMinute,
      );

      while (current.isBefore(bedEnd)) {
        if (current.isAfter(now)) {
          // 首条通知使用好友的模板文案（如果有新的未消费提醒）
          final String msg;
          if (peerCareBody != null) {
            msg = '好友提醒你：$peerCareBody';
            peerCareBody = null; // 仅首条使用
          } else {
            msg = messages[rng.nextInt(messages.length)];
          }
          await _plugin.zonedSchedule(
            id: id,
            title: '渴了么',
            body: msg,
            scheduledDate: current,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: _channelDesc,
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
              macOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          id++;
        }
        current = current.add(Duration(minutes: stepMin));
      }
    }

    debugPrint('NotificationService: scheduled $id notifications');

    // 标记该好友提醒已消费，下次调度不再重复使用
    if (peerCareRemindId != null) {
      await prefs.setString(_consumedCareRemindIdPrefKey, peerCareRemindId);
    }
  }

  Future<void> showTestNotification({String reminderStyle = '温柔'}) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final remind = await BackendApiService.instance.fetchLatestCareRemind();
      if (remind != null) {
        final remindId = remind['id'] as String?;
        final body = remind['templateBody'] as String?;
        final consumed = prefs.getString(_consumedCareRemindIdPrefKey);
        if (remindId != null &&
            body != null &&
            body.isNotEmpty &&
            remindId != consumed) {
          await showPeerCareNotification(
            title: '渴了么',
            body: '好友提醒你：$body',
          );
          await prefs.setString(_consumedCareRemindIdPrefKey, remindId);
        }
      }
    } catch (e) {
      debugPrint('showTestNotification peer care fetch failed: $e');
    }

    final messages = switch (reminderStyle) {
      '活泼' => _livelyMessages,
      '严肃' => _seriousMessages,
      _ => _gentleMessages,
    };
    final msg = messages[Random().nextInt(messages.length)];

    await _plugin.show(
      id: 9999,
      title: '渴了么',
      body: msg,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// 调度自定义提醒（V2 新增）
  Future<void> scheduleCustomReminder({
    required int id,
    required String title,
    required DateTime scheduledDate,
    String repeat = 'none',
  }) async {
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );
    if (scheduledTZ.isBefore(tz.TZDateTime.now(tz.local))) {
      if (repeat == 'none') return;
    }
    await _plugin.zonedSchedule(
      id: id,
      title: '渴了么 · 自定义提醒',
      body: title,
      scheduledDate: scheduledTZ,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'keleme_custom_reminder',
          '自定义提醒',
          channelDescription: '用户或 AI 设置的自定义提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: repeat == 'daily'
          ? DateTimeComponents.time
          : repeat == 'weekly'
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
    );
  }

  /// 取消单个自定义提醒
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  /// 取消计划提醒（ID 范围 1000-1019，最多 12 个槽位 + 缓冲）
  Future<void> cancelPlanReminders() async {
    for (var id = 1000; id < 1020; id++) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
