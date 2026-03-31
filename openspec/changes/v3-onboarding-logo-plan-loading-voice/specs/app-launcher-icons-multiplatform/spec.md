## ADDED Requirements

### Requirement: 多平台应用图标与当前品牌一致

iOS 与 macOS 应用所使用的启动器图标 MUST 与产品当前品牌视觉一致，并与已更新的 Android APK 侧图标同源或等价；安装到系统主屏幕后，用户 MUST 能识别为同一应用品牌。

#### Scenario: iOS 主屏幕图标

- **WHEN** 用户在 iOS 设备上安装本应用
- **THEN** 主屏幕与设置页中的应用图标为更新后的品牌图标，无旧版或占位图

#### Scenario: macOS 程序坞与关于

- **WHEN** 用户在 macOS 上构建并运行应用
- **THEN** 程序坞、关于窗口或应用切换器中的图标为更新后的品牌图标
