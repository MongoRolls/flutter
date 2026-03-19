import 'package:hive/hive.dart';

part 'session_summary.g.dart';

@HiveType(typeId: 1)
class SessionSummary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String summary;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final List<String> topics;

  SessionSummary({
    required this.id,
    required this.summary,
    required this.date,
    required this.topics,
  });
}
