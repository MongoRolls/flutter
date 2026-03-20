class Achievement {
  final String id;
  final String title;
  final String iconEmoji;
  final String description;
  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.iconEmoji,
    required this.description,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'iconEmoji': iconEmoji,
    'description': description,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
    id: map['id'] as String,
    title: map['title'] as String,
    iconEmoji: map['iconEmoji'] as String,
    description: map['description'] as String,
    isUnlocked: map['isUnlocked'] as bool? ?? false,
    unlockedAt: map['unlockedAt'] != null
        ? DateTime.parse(map['unlockedAt'] as String)
        : null,
  );

  /// 预置成就列表
  static List<Achievement> get defaults => [
    Achievement(
      id: 'first_drink',
      title: '初心一滴',
      iconEmoji: '💧',
      description: '第一次喝水记录',
    ),
    Achievement(
      id: 'week_streak',
      title: '一周连击',
      iconEmoji: '🔥',
      description: '连续达标 7 天',
    ),
    Achievement(
      id: 'month_streak',
      title: '月度坚持',
      iconEmoji: '🌊',
      description: '连续达标 30 天',
    ),
    Achievement(
      id: 'first_care',
      title: '首次关怀',
      iconEmoji: '❤️',
      description: '第一次发送心连心关怀',
    ),
    Achievement(
      id: 'buddy_plan',
      title: '搭子精神',
      iconEmoji: '🤝',
      description: '完成搭子计划挑战',
    ),
    Achievement(
      id: 'iron_man',
      title: '铁人',
      iconEmoji: '🏆',
      description: '完成铁人挑战',
    ),
  ];
}
