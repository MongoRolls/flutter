/// 组队挑战（服务端为主 + 可选本地占位）
class Challenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int durationDays;
  final String rewardBadgeId;
  bool isJoined;
  int currentProgress;

  /// 服务端字段
  final String? status;
  final int? teamProgressMl;
  final int? memberCount;
  final bool? selfContributed;
  final String? goalType;
  final int? goalValue;
  final String? inviteCode;
  final String? role;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? resultAcknowledgedAt;
  /// 服务端「我的挑战」列表中的当日个人饮水量（用于 individual_daily 进度）
  final int? myTodayMl;
  final bool fromServer;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.durationDays,
    required this.rewardBadgeId,
    this.isJoined = false,
    this.currentProgress = 0,
    this.status,
    this.teamProgressMl,
    this.memberCount,
    this.selfContributed,
    this.goalType,
    this.goalValue,
    this.inviteCode,
    this.role,
    this.periodStart,
    this.periodEnd,
    this.resultAcknowledgedAt,
    this.myTodayMl,
    this.fromServer = false,
  });

  double get progressRatio {
    if (fromServer) {
      final team = teamProgressMl ?? 0;
      final gv = goalValue ?? 2000;
      final gt = goalType ?? 'individual_daily';
      if (gt == 'team_total' && gv > 0) {
        return (team / gv).clamp(0.0, 1.0);
      }
      if (gt == 'individual_daily' && gv > 0) {
        final my = myTodayMl ?? 0;
        return (my / gv).clamp(0.0, 1.0);
      }
      final days = durationDays.clamp(1, 366);
      final denom = gv * days;
      return denom > 0 ? (team / denom).clamp(0.0, 1.0) : 0.0;
    }
    return durationDays > 0 ? (currentProgress / durationDays).clamp(0.0, 1.0) : 0.0;
  }

  bool get isCompleted {
    if (fromServer) {
      return status == 'settled';
    }
    return currentProgress >= durationDays;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'durationDays': durationDays,
    'rewardBadgeId': rewardBadgeId,
    'isJoined': isJoined,
    'currentProgress': currentProgress,
    'status': status,
    'teamProgressMl': teamProgressMl,
    'memberCount': memberCount,
    'selfContributed': selfContributed,
    'goalType': goalType,
    'goalValue': goalValue,
    'inviteCode': inviteCode,
    'role': role,
    'periodStart': periodStart?.toIso8601String(),
    'periodEnd': periodEnd?.toIso8601String(),
    'resultAcknowledgedAt': resultAcknowledgedAt?.toIso8601String(),
    'myTodayMl': myTodayMl,
    'fromServer': fromServer,
  };

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    emoji: map['emoji'] as String,
    durationDays: map['durationDays'] as int,
    rewardBadgeId: map['rewardBadgeId'] as String,
    isJoined: map['isJoined'] as bool? ?? false,
    currentProgress: map['currentProgress'] as int? ?? 0,
    status: map['status'] as String?,
    teamProgressMl: map['teamProgressMl'] as int?,
    memberCount: map['memberCount'] as int?,
    selfContributed: map['selfContributed'] as bool?,
    goalType: map['goalType'] as String?,
    goalValue: map['goalValue'] as int?,
    inviteCode: map['inviteCode'] as String?,
    role: map['role'] as String?,
    periodStart: map['periodStart'] != null
        ? DateTime.tryParse(map['periodStart'] as String)
        : null,
    periodEnd: map['periodEnd'] != null
        ? DateTime.tryParse(map['periodEnd'] as String)
        : null,
    resultAcknowledgedAt: map['resultAcknowledgedAt'] != null
        ? DateTime.tryParse(map['resultAcknowledgedAt'] as String)
        : null,
    myTodayMl: map['myTodayMl'] as int?,
    fromServer: map['fromServer'] as bool? ?? false,
  );

  /// 本地连续打卡类挑战（进度与连续达标天数挂钩，存 SharedPreferences）
  static List<Challenge> get defaults => [
    Challenge(
      id: 'buddy_plan',
      title: '搭子计划',
      description: '连续 30 天每日达标',
      emoji: '🤝',
      durationDays: 30,
      rewardBadgeId: 'buddy_plan',
    ),
    Challenge(
      id: 'iron_man',
      title: '铁人挑战',
      description: '连续 7 天每天达标',
      emoji: '🔥',
      durationDays: 7,
      rewardBadgeId: 'iron_man',
    ),
    Challenge(
      id: 'early_bird',
      title: '早起补水',
      description: '连续 5 天 8 点前喝第一杯',
      emoji: '🌅',
      durationDays: 5,
      rewardBadgeId: 'early_bird',
    ),
  ];

  factory Challenge.fromServerItem(Map<String, dynamic> json) {
    final ps = DateTime.tryParse(json['periodStart'] as String? ?? '');
    final pe = DateTime.tryParse(json['periodEnd'] as String? ?? '');
    if (ps == null || pe == null) {
      throw FormatException('invalid challenge period');
    }
    final durationDays = pe.difference(ps).inDays.clamp(1, 366);
    final gt = json['goalType'] as String? ?? 'individual_daily';
    final gv = json['goalValue'] as int? ?? 2000;
    return Challenge(
      id: json['challengeId'] as String,
      title: json['title'] as String,
      description: gt == 'team_total'
          ? '团队累计达标 $gv ml'
          : '每人每日达标饮水 $gv ml',
      emoji: '🤝',
      durationDays: durationDays,
      rewardBadgeId: 'team_challenge',
      isJoined: true,
      currentProgress: 0,
      status: json['status'] as String?,
      teamProgressMl: json['teamProgress'] as int?,
      memberCount: json['memberCount'] as int?,
      selfContributed: json['selfContributed'] as bool?,
      goalType: gt,
      goalValue: gv,
      inviteCode: json['inviteCode'] as String?,
      role: json['role'] as String?,
      periodStart: ps,
      periodEnd: pe,
      resultAcknowledgedAt: json['resultAcknowledgedAt'] != null
          ? DateTime.tryParse(json['resultAcknowledgedAt'] as String)
          : null,
      myTodayMl: (json['myTodayMl'] as num?)?.toInt(),
      fromServer: true,
    );
  }
}
