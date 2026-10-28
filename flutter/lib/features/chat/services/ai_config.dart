import 'package:shared_preferences/shared_preferences.dart';

/// AI generation settings. Provider credentials belong only on the backend.
class AiConfig {
  final double temperature;
  final int maxTokens;

  const AiConfig({this.temperature = 0.7, this.maxTokens = 2048});

  static Future<AiConfig> load() async {
    // Remove obsolete client credentials without reading or logging their values.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('deepseek_api_key');
    await prefs.remove('ai_use_backend_proxy');
    return const AiConfig();
  }
}
