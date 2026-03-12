# 渴了么 Flutter 启动指南

这个仓库里的 Flutter 项目实际位于 `ke_le_me/` 目录。下面这份文档按 Step by Step 整理了本项目常用的 Flutter 安装、配置、启动和排查方式。

## Step 1: 确认项目目录

从仓库根目录进入 Flutter 工程目录：

```bash
cd /Users/admin/Desktop/code/flutter/ke_le_me
```

后续大部分 Flutter 命令都建议在这个目录下执行。

## Step 2: 安装 Flutter

如果你的机器还没有安装 Flutter，可以按官方文档安装：

- Flutter 安装文档：https://docs.flutter.dev/get-started/install

安装完成后，确认命令可用：

```bash
flutter --version
```

本项目当前 `pubspec.yaml` 中声明的 Dart SDK 版本为：

```yaml
environment:
  sdk: ^3.11.1
```

因此建议使用和该版本兼容的 Flutter SDK。

## Step 3: 检查开发环境

先执行：

```bash
flutter doctor
```

重点看以下几项是否正常：

- Flutter SDK
- Xcode 和 macOS desktop support
- Chrome
- Android toolchain
- Android Studio

如果 `flutter doctor` 有红字，优先先修复，再继续启动项目。

## Step 4: 拉取项目依赖

首次运行项目，先安装依赖：

```bash
flutter pub get
```

本项目当前主要依赖：

- `shared_preferences`
- `google_fonts`
- `cupertino_icons`

## Step 5: 查看当前可用设备

查看 Flutter 识别到的设备：

```bash
flutter devices
```

你当前环境里已经识别到的设备是：

- `macos`
- `chrome`

也就是说，现在可以直接运行：

```bash
flutter run -d macos
flutter run -d chrome
```

## Step 6: 启动项目

### 方式 A: 启动 macOS 桌面版

这是当前最推荐的本地调试方式：

```bash
flutter run -d macos
```

如果未启用 macOS desktop support，可以自行执行：

```bash
flutter config --enable-macos-desktop
```

说明：这条命令会修改本机 Flutter 配置。

### 方式 B: 启动 Web 版本

如果想快速预览页面，也可以直接跑 Web：

```bash
flutter run -d chrome
```

### 方式 C: 启动 Android

只有在 Flutter 检测到 Android 设备后，才会有 `Android_device_id`。

先查看：

```bash
flutter devices
```

如果输出里出现类似：

```bash
Android SDK built for arm64 • emulator-5554 • android-arm64 • Android 14
```

那么其中的 `emulator-5554` 就是 `Android_device_id`，启动命令为：

```bash
flutter run -d emulator-5554
```

如果当前没有 Android 设备，可以先：

1. 打开 Android Studio
2. 进入 Device Manager
3. 创建并启动一个 Android 模拟器
4. 再执行 `flutter devices`
5. 最后执行 `flutter run -d <android_device_id>`

## Step 7: 启动 iPhone 模拟器

如果你要跑 iOS，可以先打开模拟器：

```bash
open -a Simulator
```

然后查看设备：

```bash
flutter devices
```

启动方式：

```bash
flutter run -d ios
```

如果有多个 iOS 设备，建议改用明确的设备 ID。

## Step 8: 日常开发常用命令

```bash
flutter pub get
flutter run
flutter run -d macos
flutter run -d chrome
flutter test
flutter test test/widget_test.dart
flutter analyze
flutter format .
flutter build apk
flutter build ios
flutter build macos
flutter build web
```

## Step 9: 运行中的快捷操作

执行 `flutter run` 之后，终端里常用快捷键有：

- `r`: Hot reload
- `R`: Hot restart
- `h`: 查看帮助
- `q`: 退出运行
- `d`: 断开调试但保留应用运行

## Step 10: 常见问题排查

### 1. `flutter devices` 看不到设备

先检查：

```bash
flutter doctor
flutter devices
```

常见原因：

- Android 模拟器还没启动
- iPhone 模拟器还没启动
- Xcode 或 Android 工具链没有配置好
- USB 真机没有开启开发者模式

### 2. 依赖或构建缓存异常

可以按下面顺序重试：

```bash
flutter clean
flutter pub get
flutter run -d macos
```

### 3. 需要更详细日志

```bash
flutter run -v
```

### 4. macOS 运行时字体下载失败

这个项目当前使用了 `google_fonts`。如果在 macOS 桌面版运行时看到类似下面的错误：

```text
Failed to load font with url https://fonts.gstatic.com/...
```

通常表示应用没有网络访问权限，或者当前环境禁止访问 Google Fonts。

本项目的 `macos/Runner/DebugProfile.entitlements` 当前只有：

- `com.apple.security.app-sandbox`
- `com.apple.security.cs.allow-jit`
- `com.apple.security.network.server`

如果后续需要让 macOS 调试版正常联网，通常还需要补充：

- `com.apple.security.network.client`

另外，如果网络环境无法访问 Google Fonts，也可以考虑把字体改成本地资源，而不是运行时在线下载。

## Step 11: 本项目最短启动路径

如果你只是想尽快把项目跑起来，直接执行下面三条：

```bash
cd /Users/admin/Desktop/code/flutter/ke_le_me
flutter pub get
flutter run -d macos
```

如果要跑 Web，则把最后一条改成：

```bash
flutter run -d chrome
```

## 参考

- Flutter 官方文档：https://docs.flutter.dev/
- Flutter 安装指南：https://docs.flutter.dev/get-started/install
