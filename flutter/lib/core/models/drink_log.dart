class DrinkLog {
  final String time;
  final String icon;
  final String description;
  final int ml;

  DrinkLog({
    required this.time,
    required this.icon,
    required this.description,
    required this.ml,
  });

  Map<String, dynamic> toMap() => {
        'time': time,
        'icon': icon,
        'description': description,
        'ml': ml,
      };

  factory DrinkLog.fromMap(Map<String, dynamic> m) => DrinkLog(
        time: m['time'] ?? '',
        icon: m['icon'] ?? '💧',
        description: m['description'] ?? '',
        ml: m['ml'] ?? 0,
      );
}
