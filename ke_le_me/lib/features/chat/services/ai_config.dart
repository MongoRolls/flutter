class AiConfig {
  static const _defaultApiKey =
      String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: _builtinKey);

  static const _builtinKey =
      'sk-nnbD8jXM5rn3VDMHJ7JC3Hdxd4Y0EOO9upf0oMD83k4X7WJM';

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

  factory AiConfig.fromEnvironment() => const AiConfig(
        apiKey: _defaultApiKey,
      );
}
