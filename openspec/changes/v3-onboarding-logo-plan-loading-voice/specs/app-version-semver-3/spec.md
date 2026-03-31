## ADDED Requirements

### Requirement: 应用版本号为 3.0 系列

Flutter 工程 `pubspec.yaml` 中的 `version` MUST 使用 **3.0** 主版本线（例如 `3.0.0+build`），且各平台构建产物中用户可见或审核用的版本号（如 iOS `CFBundleShortVersionString`、Android `versionName`）MUST 与此一致。

#### Scenario: pubspec 与构建一致

- **WHEN** 开发者在 `flutter/` 执行 `flutter build` 针对 iOS / Android / macOS
- **THEN** 产出包内版本号与 `pubspec.yaml` 声明的 3.0 系列一致（或符合团队约定的 build 号递增规则）
