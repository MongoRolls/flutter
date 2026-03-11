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
  bool exerciseReminderEnabled;
  bool meetingPauseEnabled;
  bool morningPlanEnabled;
  bool onboardingCompleted;

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
    this.exerciseReminderEnabled = true,
    this.meetingPauseEnabled = false,
    this.morningPlanEnabled = false,
    this.onboardingCompleted = false,
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
        'exerciseReminderEnabled': exerciseReminderEnabled,
        'meetingPauseEnabled': meetingPauseEnabled,
        'morningPlanEnabled': morningPlanEnabled,
        'onboardingCompleted': onboardingCompleted,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        nickname: m['nickname'] ?? '',
        gender: m['gender'] ?? '男',
        activityLevel: m['activityLevel'] ?? '久坐',
        weight: (m['weight'] ?? 65).toDouble(),
        dailyGoalMl: m['dailyGoalMl'] ?? 2300,
        wakeTime: m['wakeTime'] ?? '07:00',
        bedTime: m['bedTime'] ?? '23:00',
        reminderIntervalMin: m['reminderIntervalMin'] ?? 90,
        reminderStyle: m['reminderStyle'] ?? '温柔',
        notificationsEnabled: m['notificationsEnabled'] ?? true,
        exerciseReminderEnabled: m['exerciseReminderEnabled'] ?? true,
        meetingPauseEnabled: m['meetingPauseEnabled'] ?? false,
        morningPlanEnabled: m['morningPlanEnabled'] ?? false,
        onboardingCompleted: m['onboardingCompleted'] ?? false,
      );
}
