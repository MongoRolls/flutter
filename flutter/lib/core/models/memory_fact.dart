import 'package:hive/hive.dart';

part 'memory_fact.g.dart';

@HiveType(typeId: 0)
class MemoryFact extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category; // health | preference | habit | event | reminder

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? expiresAt;

  @HiveField(5)
  final int importance; // 1-5

  MemoryFact({
    required this.id,
    required this.category,
    required this.content,
    required this.createdAt,
    this.expiresAt,
    this.importance = 3,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
