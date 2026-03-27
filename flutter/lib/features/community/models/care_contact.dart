class CareContact {
  final String id;
  final String name;
  final String relationship; // 'mom' | 'dad' | 'partner' | 'friend'
  final String avatarEmoji;
  /// 对方目标饮水量（占位；后续可由服务端同步对方 UserProfile.dailyGoalMl）
  final int mockDailyGoalMl;
  /// 对方今日已喝（占位；后续可由服务端同步或留空）
  int mockTodayMl;

  CareContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.avatarEmoji,
    this.mockDailyGoalMl = 2000,
    this.mockTodayMl = 0,
  });

  double get progress => mockDailyGoalMl > 0
      ? (mockTodayMl / mockDailyGoalMl).clamp(0.0, 1.0)
      : 0.0;

  /// 状态：'done' / 'inProgress' / 'notStarted'
  String get status {
    if (progress >= 1.0) return 'done';
    if (mockTodayMl > 0) return 'inProgress';
    return 'notStarted';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'avatarEmoji': avatarEmoji,
    'mockDailyGoalMl': mockDailyGoalMl,
    'mockTodayMl': mockTodayMl,
  };

  factory CareContact.fromMap(Map<String, dynamic> map) => CareContact(
    id: map['id'] as String,
    name: map['name'] as String,
    relationship: map['relationship'] as String,
    avatarEmoji: map['avatarEmoji'] as String,
    mockDailyGoalMl: map['mockDailyGoalMl'] as int? ?? 2000,
    mockTodayMl: map['mockTodayMl'] as int? ?? 0,
  );

  /// 关系类型对应的显示文字
  String get relationshipLabel => switch (relationship) {
    'mom' => '妈妈',
    'dad' => '爸爸',
    'partner' => '恋人',
    'friend' => '朋友',
    _ => relationship,
  };
}
