import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/backend_api_service.dart';

class AiConfig {
  static const _envApiKey =
      String.fromEnvironment('DEEPSEEK_API_KEY');

  static const _prefsKey = 'deepseek_api_key';
  static const _useBackendKey = 'ai_use_backend_proxy';

  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final String keySource;
  final bool useBackendProxy;

  const AiConfig({
    this.baseUrl = 'https://api.deepseek.com',
    this.apiKey = '',
    this.model = 'deepseek-chat',
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.keySource = 'none',
    this.useBackendProxy = false,
  });

  /// Priority:
  /// 1. Backend proxy (if enabled and backend is authenticated)
  /// 2. --dart-define
  /// 3. SharedPreferences
  /// 4. Built-in key (fallback)
  static Future<AiConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final useProxy = prefs.getBool(_useBackendKey) ?? true;
    final backend = BackendApiService.instance;

    if (useProxy && backend.isAuthenticated) {
      debugPrint('AiConfig: source=backend-proxy');
      return AiConfig(
        baseUrl: '${backend.baseUrl}/api/ai',
        apiKey: '',
        keySource: 'backend-proxy',
        useBackendProxy: true,
      );
    }

    String key;
    String source;
    if (_envApiKey.isNotEmpty) {
      key = _envApiKey;
      source = 'dart-define';
    } else {
      final saved = prefs.getString(_prefsKey) ?? '';
      key = saved;
      source = saved.isNotEmpty ? 'saved' : 'none';
    }
    if (key.isNotEmpty) {
      final masked = key.length > 8
          ? '${key.substring(0, 5)}...${key.substring(key.length - 4)}'
          : '***';
      debugPrint('AiConfig: source=$source, key=$masked');
    } else {
      debugPrint('AiConfig: source=$source (no API key — backend proxy required)');
    }
    return AiConfig(apiKey: key, keySource: source);
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.trim());
  }

  static Future<String> getSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? '';
  }

  static Future<void> setUseBackendProxy(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useBackendKey, value);
  }

  bool get hasApiKey => apiKey.isNotEmpty || useBackendProxy;
}
