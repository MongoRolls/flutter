class CareContact {
  /// 对方用户 id（与后端 `contactId` 一致）
  final String id;
  final String name;

  /// 后端 `CareContact` 行 id，用于 `DELETE /api/care/contacts/:id`
  final String? serverRowId;

  /// 关系类型：'family' | 'friend'
  final String relationship;
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
    this.serverRowId,
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
    if (serverRowId != null) 'serverRowId': serverRowId,
    'relationship': relationship,
    'avatarEmoji': avatarEmoji,
    'mockDailyGoalMl': mockDailyGoalMl,
    'mockTodayMl': mockTodayMl,
  };

  factory CareContact.fromMap(Map<String, dynamic> map) => CareContact(
    id: map['id'] as String,
    name: map['name'] as String,
    serverRowId: map['serverRowId'] as String?,
    relationship: _normalizeRelationship(map['relationship'] as String?),
    avatarEmoji: map['avatarEmoji'] as String,
    mockDailyGoalMl: map['mockDailyGoalMl'] as int? ?? 2000,
    mockTodayMl: map['mockTodayMl'] as int? ?? 0,
  );

  /// 将历史值（mom/dad/partner）迁移为 family / friend。
  static String _normalizeRelationship(String? raw) {
    if (raw == null) return 'friend';
    return switch (raw) {
      'family' || 'friend' => raw,
      'mom' || 'dad' || 'partner' => 'family',
      _ => 'friend',
    };
  }

  /// 关系类型对应的显示文字
  String get relationshipLabel => switch (relationship) {
    'family' => '家人',
    _ => '朋友',
  };
}
