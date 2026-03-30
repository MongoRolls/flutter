import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/models/custom_reminder.dart';
import '../../../../core/services/notification_service.dart';
import '../../services/function_registry.dart';

List<FunctionDefinition> createReminderTools() {
  return [
    FunctionDefinition(
      name: 'set_reminder',
      description:
          '在用户明确需要定时提醒（体检、吃药、某时刻喝水等）时调用。'
          '用户说「N 分钟后/小时后」时**优先传 offset_minutes**（由本机时钟计算，避免模型算错绝对时间）。'
          '勿把随意数字或闲聊当作提醒时间；时间或意图不清时先文字确认，不要调用。',
      parameters: {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': '提醒内容'},
          'datetime': {
            'type': 'string',
            'description': '绝对时刻，ISO 8601（本地时区可无 Z）。与 offset_minutes 二选一；有 offset_minutes 时忽略此项',
          },
          'offset_minutes': {
            'type': 'integer',
            'description':
                '相对「当前这一刻」的分钟数，用于「15 分钟后」「30 分钟后」等；仅 repeat=none 时有效。'
                '优先使用，避免自行拼 ISO 导致早于真实时间而失败',
          },
          'repeat': {
            'type': 'string',
            'enum': ['none', 'daily', 'weekly'],
            'description': '重复模式，默认 none',
          },
        },
        'required': ['title'],
      },
      handler: (args) async {
        final title = args['title'] as String;
        final repeat = args['repeat'] as String? ?? 'none';
        final rawOffset = args['offset_minutes'];

        DateTime? dt;
        if (rawOffset != null) {
          final offset = rawOffset is int
              ? rawOffset
              : int.tryParse(rawOffset.toString());
          if (offset == null) {
            return jsonEncode({'error': 'offset_minutes 须为整数'});
          }
          if (repeat != 'none') {
            return jsonEncode({'error': '相对时间 offset_minutes 仅支持不重复（none）的提醒'});
          }
          if (offset <= 0) {
            return jsonEncode({'error': 'offset_minutes 须为正整数'});
          }
          dt = DateTime.now().add(Duration(minutes: offset));
        } else {
          final datetimeStr = args['datetime'] as String?;
          if (datetimeStr == null || datetimeStr.isEmpty) {
            return jsonEncode({'error': '请提供 datetime 或 offset_minutes'});
          }
          dt = DateTime.tryParse(datetimeStr);
          if (dt == null) {
            return jsonEncode({'error': '无效的时间格式'});
          }
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
          'datetime': dt.toIso8601String(),
          'repeat': repeat,
        });
      },
    ),
  ];
}
