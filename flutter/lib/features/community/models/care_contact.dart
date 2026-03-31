class CareContact {
  /// 对方用户 id（与后端 `contactId` 一致）
  final String id;
  final String name;

  /// 后端 `CareContact` 行 id，用于 `DELETE /api/care/contacts/:id`
  final String? serverRowId;

  /// 关系类型：'family' | 'friend'
  final String relationship;
  final String avatarEmoji;

  /// 对方目标饮水量（由 `GET /api/care/peers/hydration` 与本地缓存填充）
  final int mockDailyGoalMl;

  /// 对方今日已喝（同上）
  final int mockTodayMl;

  /// 是否已向好友发起「接收喝水提醒」邀请（本地持久化）。
  final bool friendPushInviteEnabled;

  /// 对方是否允许展示饮水摘要（`visible: false` 时隐藏毫升数）
  final bool hydrationVisible;

  CareContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.avatarEmoji,
    this.serverRowId,
    this.mockDailyGoalMl = 2000,
    this.mockTodayMl = 0,
    this.friendPushInviteEnabled = false,
    this.hydrationVisible = true,
  });

  CareContact copyWith({
    String? id,
    String? name,
    String? relationship,
    String? avatarEmoji,
    String? serverRowId,
    int? mockDailyGoalMl,
    int? mockTodayMl,
    bool? friendPushInviteEnabled,
    bool? hydrationVisible,
  }) {
    return CareContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      serverRowId: serverRowId ?? this.serverRowId,
      mockDailyGoalMl: mockDailyGoalMl ?? this.mockDailyGoalMl,
      mockTodayMl: mockTodayMl ?? this.mockTodayMl,
      friendPushInviteEnabled:
          friendPushInviteEnabled ?? this.friendPushInviteEnabled,
      hydrationVisible: hydrationVisible ?? this.hydrationVisible,
    );
  }

  double get progress => !hydrationVisible
      ? 0.0
      : mockDailyGoalMl > 0
      ? (mockTodayMl / mockDailyGoalMl).clamp(0.0, 1.0)
      : 0.0;

  /// 状态：'done' / 'inProgress' / 'notStarted'
  String get status {
    if (!hydrationVisible) return 'notStarted';
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
    'friendPushInviteEnabled': friendPushInviteEnabled,
    'hydrationVisible': hydrationVisible,
  };

  factory CareContact.fromMap(Map<String, dynamic> map) => CareContact(
    id: map['id'] as String,
    name: map['name'] as String,
    serverRowId: map['serverRowId'] as String?,
    relationship: _normalizeRelationship(map['relationship'] as String?),
    avatarEmoji: map['avatarEmoji'] as String,
    mockDailyGoalMl: map['mockDailyGoalMl'] as int? ?? 2000,
    mockTodayMl: map['mockTodayMl'] as int? ?? 0,
    friendPushInviteEnabled: _readBool(map['friendPushInviteEnabled']),
    hydrationVisible: map['hydrationVisible'] is bool
        ? map['hydrationVisible'] as bool
        : true,
  );

  static bool _readBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v == 'true' || v == '1';
    return false;
  }

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
