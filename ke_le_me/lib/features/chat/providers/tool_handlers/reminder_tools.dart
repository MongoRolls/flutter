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

        final dt = DateTime.tryParse(datetimeStr);
        if (dt == null) {
          return jsonEncode({'error': '无效的时间格式'});
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
