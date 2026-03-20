class Challenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int durationDays;
  final String rewardBadgeId;
  bool isJoined;
  int currentProgress; // 本地计算

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.durationDays,
    required this.rewardBadgeId,
    this.isJoined = false,
    this.currentProgress = 0,
  });

  double get progressRatio =>
      durationDays > 0 ? (currentProgress / durationDays).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => currentProgress >= durationDays;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'durationDays': durationDays,
    'rewardBadgeId': rewardBadgeId,
    'isJoined': isJoined,
    'currentProgress': currentProgress,
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
  );

  /// MVP 预置 3 种挑战
  static List<Challenge> get defaults => [
    Challenge(
      id: 'buddy_plan',
      title: '搭子计划',
      description: '邀请好友组队，共同每日达标',
      emoji: '🤝',
      durationDays: 30,
      rewardBadgeId: 'buddy_plan',
    ),
    Challenge(
      id: 'iron_man',
      title: '铁人挑战',
      description: '连续 7 天每天 100% 完成',
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
}
