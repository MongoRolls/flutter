import 'dart:math';

class CareContact {
  final String id;
  final String name;
  final String relationship; // 'mom' | 'dad' | 'partner' | 'friend'
  final String avatarEmoji;
  final int mockDailyGoalMl;
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

  /// 每日刷新 mock 水量（在合理范围内随机）
  void refreshMockWater() {
    final rng = Random();
    // 随机产生 0~120% 的饮水量
    final ratio = rng.nextDouble() * 1.2;
    mockTodayMl = (mockDailyGoalMl * ratio).round().clamp(
      0,
      mockDailyGoalMl + 500,
    );
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

  /// 预置联系人（用于首次安装时的 mock 数据）
  static List<CareContact> get defaults => [
    CareContact(
      id: 'mock_mom',
      name: '妈妈',
      relationship: 'mom',
      avatarEmoji: '👩',
      mockDailyGoalMl: 2000,
    ),
    CareContact(
      id: 'mock_partner',
      name: '小明',
      relationship: 'partner',
      avatarEmoji: '🧡',
      mockDailyGoalMl: 2000,
    ),
    CareContact(
      id: 'mock_dad',
      name: '爸爸',
      relationship: 'dad',
      avatarEmoji: '👨',
      mockDailyGoalMl: 2000,
    ),
  ];
}
