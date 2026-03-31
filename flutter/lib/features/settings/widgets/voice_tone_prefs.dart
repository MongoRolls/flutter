import 'package:shared_preferences/shared_preferences.dart';

/// 音色预设（仅本地 UI / 持久化，不接后端）。
class VoiceTonePreset {
  const VoiceTonePreset({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String emoji;
  final String title;
  final String subtitle;
}

/// 预设列表与 SharedPreferences 读写（设置页用 Chip 与 [VoiceTonePrefs.presets] 展示）。
class VoiceTonePrefs {
  VoiceTonePrefs._();

  static const String storageKey = 'voice_tone_preset_id';
  static const String defaultId = 'gentle';

  /// 两字简称，参考 MiniMax 常见分类（如甜美女声、青涩青年、新闻/播报类）。
  static const List<VoiceTonePreset> presets = [
    VoiceTonePreset(
      id: 'gentle',
      emoji: '💝',
      title: '甜美',
      subtitle: '对应甜美女声等柔和风格',
    ),
    VoiceTonePreset(
      id: 'lively',
      emoji: '😄',
      title: '青朗',
      subtitle: '对应青涩青年等明快风格',
    ),
    VoiceTonePreset(
      id: 'calm',
      emoji: '📻',
      title: '播报',
      subtitle: '对应新闻女声、播报男声等清晰播报',
    ),
  ];

  static Future<String> getSelectedId() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(storageKey);
    if (id != null && presets.any((e) => e.id == id)) return id;
    return defaultId;
  }

  static Future<void> setSelectedId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(storageKey, id);
  }

  static String titleForId(String id) {
    for (final e in presets) {
      if (e.id == id) return e.title;
    }
    return presets.first.title;
  }
}
