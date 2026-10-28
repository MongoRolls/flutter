import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ke_le_me/features/chat/services/ai_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('removes legacy credentials and proxy opt-out without changing settings', () async {
    SharedPreferences.setMockInitialValues({
      'deepseek_api_key': 'test-only-legacy-key',
      'ai_use_backend_proxy': false,
      'unrelated_preference': 'keep',
    });
    final config = await AiConfig.load();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('deepseek_api_key'), isFalse);
    expect(prefs.containsKey('ai_use_backend_proxy'), isFalse);
    expect(prefs.getString('unrelated_preference'), 'keep');
    expect(config.temperature, 0.7);
    expect(config.maxTokens, 2048);
  });
}
