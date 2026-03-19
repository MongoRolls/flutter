import 'package:shared_preferences/shared_preferences.dart';

class AiConfig {
  static const _envApiKey =
      String.fromEnvironment('DEEPSEEK_API_KEY');

  static const _builtinKey = 'sk-b2a0eee592f645ea91103f921bf358e0';

  static const _prefsKey = 'deepseek_api_key';

  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;

  const AiConfig({
    this.baseUrl = 'https://api.deepseek.com',
    this.apiKey = '',
    this.model = 'deepseek-chat',
    this.temperature = 0.7,
    this.maxTokens = 2048,
  });

  /// Priority: --dart-define > SharedPreferences > built-in key.
  static Future<AiConfig> load() async {
    if (_envApiKey.isNotEmpty) {
      return const AiConfig(apiKey: _envApiKey);
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey) ?? '';
    final key = saved.isNotEmpty ? saved : _builtinKey;
    return AiConfig(apiKey: key);
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.trim());
  }

  static Future<String> getSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? '';
  }

  bool get hasApiKey => apiKey.isNotEmpty;
}
