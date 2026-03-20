import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/models/custom_reminder.dart';
import '../../../../core/services/notification_service.dart';
import '../../services/function_registry.dart';

List<FunctionDefinition> createReminderTools() {
  return [
    FunctionDefinition(
      name: 'set_reminder',
      description: '为用户设置一个自定义提醒（如体检、吃药、特定时间喝水等）',
      parameters: {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': '提醒内容'},
          'datetime': {'type': 'string', 'description': '提醒时间，ISO 8601 格式'},
          'repeat': {
            'type': 'string',
            'enum': ['none', 'daily', 'weekly'],
            'description': '重复模式，默认 none',
          },
        },
        'required': ['title', 'datetime'],
      },
      handler: (args) async {
        final title = args['title'] as String;
        final datetimeStr = args['datetime'] as String;
        final repeat = args['repeat'] as String? ?? 'none';

        var dt = DateTime.tryParse(datetimeStr);
        if (dt == null) {
          return jsonEncode({'error': '无效的时间格式'});
        }

        // 如果时间已过去，对 daily/weekly 自动推移到下一个有效时刻
        final now = DateTime.now();
        if (dt.isBefore(now)) {
          if (repeat == 'daily') {
            // 推移到今天的该时刻（若仍在过去，则推到明天）
            dt = DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
            if (dt.isBefore(now)) {
              dt = dt.add(const Duration(days: 1));
            }
          } else if (repeat == 'weekly') {
            // 推移到本周同一天（若仍在过去，则推到下周）
            final daysDiff = (dt.weekday - now.weekday) % 7;
            dt = DateTime(
              now.year,
              now.month,
              now.day,
              dt.hour,
              dt.minute,
            ).add(Duration(days: daysDiff));
            if (dt.isBefore(now)) {
              dt = dt.add(const Duration(days: 7));
            }
          } else {
            // none：过去的时间直接返回错误，不调度
            return jsonEncode({'error': '提醒时间不能是过去的时间'});
          }
        }

        final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
        final reminder = CustomReminder(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          datetime: dt,
          repeat: repeat,
          notificationId: notificationId,
        );

        final box = Hive.box<CustomReminder>('custom_reminders');
        await box.put(reminder.id, reminder);

        await NotificationService.instance.scheduleCustomReminder(
          id: notificationId,
          title: title,
          scheduledDate: dt,
          repeat: repeat,
        );

        return jsonEncode({
          'success': true,
          'title': title,
          'datetime': datetimeStr,
          'repeat': repeat,
        });
      },
    ),
  ];
}
