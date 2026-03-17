class AiConfig {
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

  /// 从编译时环境变量创建（MVP 方案）
  factory AiConfig.fromEnvironment() => const AiConfig(
        apiKey: String.fromEnvironment('DEEPSEEK_API_KEY'),
      );
}
