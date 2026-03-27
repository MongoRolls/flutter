# 渴了么 (KeLeMe) - Flutter 喝水提醒应用

学习 Flutter 参加 agent 比赛的移动端项目。

**项目简介**: AI 智能喝水提醒应用，帮助用户养成健康饮水习惯。支持自定义每日目标、智能提醒、连续打卡记录等功能。

**技术栈**: Flutter 3.11+ / Dart / SharedPreferences / Flutter Local Notifications

**项目目录**: Flutter 工程位于 `ke_le_me/` 子目录中。

---

## 快速启动

```bash
cd /Users/admin/Desktop/code/flutter/ke_le_me
flutter pub get
flutter run -d macos
```

## 常用命令

```bash
flutter doctor           # 检查开发环境
flutter pub get          # 安装依赖
flutter run -d macos     # macOS 开发调试
flutter run -d chrome    # Web 版本
flutter test             # 运行测试
flutter analyze          # 静态分析 (提交前运行)
flutter format .         # 格式化代码
flutter clean            # 清理构建缓存

flutter build apk        # Android APK
flutter build ios        # iOS
flutter build macos      # macOS
flutter build web        # Web
```

## 运行时快捷键

- `r` - Hot reload
- `R` - Hot restart
- `q` - 退出

## 项目结构

```
ke_le_me/lib/
├── main.dart              # 应用入口
├── models/                # 数据模型
├── providers/             # 状态管理 (ChangeNotifier)
├── screens/               # 页面
├── services/              # 业务逻辑 (NotificationService)
├── theme/                 # 主题配置
└── widgets/               # 自定义组件
```

## 主要依赖

- `shared_preferences` - 本地数据持久化
- `google_fonts` - Google 字体库
- `flutter_local_notifications` - 本地通知
- `timezone` + `flutter_timezone` - 时区处理

## 常见问题

**macOS 字体加载失败** - 添加网络权限到 `macos/Runner/*.entitlements`:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

**依赖问题** - 清理缓存:
```bash
flutter clean && flutter pub get
```

**通知不工作** - 检查系统设置中的应用通知权限

## 参考资源

- **Flutter 官方文档**: https://docs.flutter.dev/
- **Flutter 中文网**: https://flutter.cn/
- **Dart 官方文档**: https://dart.dev/guides
- **Flutter 本地通知**: https://pub.dev/packages/flutter_local_notifications

## 项目状态

- ✅ 核心功能: 喝水记录、目标追踪、连续打卡
- ✅ 通知系统: 智能提醒、自定义风格、时区支持
- ✅ 多平台支持: iOS / Android / macOS / Web
