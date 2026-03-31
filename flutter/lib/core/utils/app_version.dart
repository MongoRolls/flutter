/// App 版本号常量（与 pubspec.yaml 保持一致，发版前手动同步）
class AppVersion {
  /// 与 pubspec.yaml 的 version 字段保持一致
  static const String version = '3.0.0';
  static const String buildDate = '2026-03-31';

  /// 完整展示字符串，如 "v2.5.1"
  static const String display = 'v$version';

  /// 设置页详细展示，如 "v2.5.1 · 2026-03-20"
  static const String detail = 'v$version · $buildDate';
}
