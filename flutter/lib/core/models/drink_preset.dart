class DrinkPreset {
  final String icon;
  final String name;
  final int ml;

  const DrinkPreset({
    required this.icon,
    required this.name,
    required this.ml,
  });

  Map<String, dynamic> toMap() => {
        'icon': icon,
        'name': name,
        'ml': ml,
      };

  factory DrinkPreset.fromMap(Map<String, dynamic> m) => DrinkPreset(
        icon: m['icon'] ?? '💧',
        name: m['name'] ?? '',
        ml: m['ml'] ?? 250,
      );

  static const List<DrinkPreset> defaults = [
    DrinkPreset(icon: '💧', name: '水杯', ml: 250),
    DrinkPreset(icon: '🥤', name: '大杯', ml: 500),
    DrinkPreset(icon: '☕', name: '咖啡', ml: 300),
  ];
}
