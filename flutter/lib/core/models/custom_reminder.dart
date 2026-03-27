import 'package:hive/hive.dart';

part 'custom_reminder.g.dart';

@HiveType(typeId: 2)
class CustomReminder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime datetime;

  @HiveField(3)
  final String repeat; // none | daily | weekly

  @HiveField(4)
  final int notificationId;

  @HiveField(5)
  final bool active;

  CustomReminder({
    required this.id,
    required this.title,
    required this.datetime,
    this.repeat = 'none',
    required this.notificationId,
    this.active = true,
  });
}
