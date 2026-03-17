import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'keleme_water_reminder';
  static const _channelName = '喝水提醒';
  static const _channelDesc = '定时提醒你喝水';

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

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
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
  }) async {
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final wakeParts = wakeTime.split(':');
    final bedParts = bedTime.split(':');
    final wakeHour = int.parse(wakeParts[0]);
    final wakeMinute = int.parse(wakeParts[1]);
    final bedHour = int.parse(bedParts[0]);
    final bedMinute = int.parse(bedParts[1]);

    final messages = switch (reminderStyle) {
      '活泼' => _livelyMessages,
      '严肃' => _seriousMessages,
      _ => _gentleMessages,
    };

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
          final msg = messages[rng.nextInt(messages.length)];
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
        current = current.add(Duration(minutes: intervalMin));
      }
    }

    debugPrint('NotificationService: scheduled $id notifications');
  }

  Future<void> showTestNotification({String reminderStyle = '温柔'}) async {
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

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
