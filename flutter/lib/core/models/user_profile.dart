class UserProfile {
  String nickname;
  String gender;
  String activityLevel;
  double weight;
  int dailyGoalMl;
  String wakeTime;
  String bedTime;
  int reminderIntervalMin;
  String reminderStyle;
  bool notificationsEnabled;
  bool onboardingCompleted;
  double? cachedLat;
  double? cachedLon;

  UserProfile({
    this.nickname = '',
    this.gender = '男',
    this.activityLevel = '久坐',
    this.weight = 65,
    this.dailyGoalMl = 2300,
    this.wakeTime = '07:00',
    this.bedTime = '23:00',
    this.reminderIntervalMin = 90,
    this.reminderStyle = '温柔',
    this.notificationsEnabled = true,
    this.onboardingCompleted = false,
    this.cachedLat,
    this.cachedLon,
  });

  int get recommendedGoal => (weight * 35).round().clamp(1500, 4000);

  Map<String, dynamic> toMap() => {
        'nickname': nickname,
        'gender': gender,
        'activityLevel': activityLevel,
        'weight': weight,
        'dailyGoalMl': dailyGoalMl,
        'wakeTime': wakeTime,
        'bedTime': bedTime,
        'reminderIntervalMin': reminderIntervalMin,
        'reminderStyle': reminderStyle,
        'notificationsEnabled': notificationsEnabled,
        'onboardingCompleted': onboardingCompleted,
        'cachedLat': cachedLat,
        'cachedLon': cachedLon,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        nickname: m['nickname'] ?? '',
        gender: m['gender'] ?? '男',
        activityLevel: m['activityLevel'] ?? '久坐',
        weight: (m['weight'] ?? 65).toDouble(),
        dailyGoalMl: m['dailyGoalMl'] ?? 2300,
        wakeTime: m['wakeTime'] ?? '07:00',
        bedTime: m['bedTime'] ?? '23:00',
        reminderIntervalMin: _sanitizeReminderInterval(m['reminderIntervalMin']),
        reminderStyle: m['reminderStyle'] ?? '温柔',
        notificationsEnabled: m['notificationsEnabled'] ?? true,
        onboardingCompleted: m['onboardingCompleted'] ?? false,
        cachedLat: (m['cachedLat'] as num?)?.toDouble(),
        cachedLon: (m['cachedLon'] as num?)?.toDouble(),
      );

  /// 避免 0 或负数导致通知调度死循环。
  static int _sanitizeReminderInterval(dynamic v) {
    final n = (v is num) ? v.round() : 90;
    if (n <= 0) return 90;
    return n.clamp(1, 24 * 60);
  }
}
