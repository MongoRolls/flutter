# Round 1 · Agent A — Dependencies + Platform Config

**并行组**：Round 1（与 Agent B、C、D 同时执行）  
**负责文件**：`pubspec.yaml`、`main.dart`、Android/iOS/macOS 平台配置  
**注意**：只写下列文件，不要碰其他任何文件

---

你正在为 Flutter 项目「渴了么」(ke_le_me/) 实施 V2 升级。你的任务是更新依赖、初始化 Hive，以及配置各平台权限。

## 你的任务

### 1. 更新 pubspec.yaml

当前 pubspec.yaml 路径：`ke_le_me/pubspec.yaml`

在 `dependencies` 中添加：
```yaml
geolocator: ^13.0.0
hive: ^2.2.3
hive_flutter: ^1.1.0
```

在 `dev_dependencies` 中添加：
```yaml
hive_generator: ^2.0.1
build_runner: ^2.4.0
```

保留所有现有依赖不变。

---

### 2. 修改 main.dart

路径：`ke_le_me/lib/main.dart`

先读取现有文件内容，然后进行以下修改：

**新增 import**：
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/memory_fact.dart';
import 'core/models/session_summary.dart';
import 'core/models/custom_reminder.dart';
```

**修改 `main()` 函数**（改为 async，添加 Hive 初始化）：

在 `WidgetsFlutterBinding.ensureInitialized()` 之后、`runApp()` 之前插入：
```dart
await Hive.initFlutter();
Hive.registerAdapter(MemoryFactAdapter());
Hive.registerAdapter(SessionSummaryAdapter());
Hive.registerAdapter(CustomReminderAdapter());
await Hive.openBox<MemoryFact>('memory_facts');
await Hive.openBox<SessionSummary>('session_summaries');
await Hive.openBox<CustomReminder>('custom_reminders');
```

保留现有的 `SystemChrome.setSystemUIOverlayStyle(...)` 调用。

> 注意：`MemoryFactAdapter`、`SessionSummaryAdapter`、`CustomReminderAdapter` 这三个类是 build_runner 从 Hive 模型自动生成的（由 Agent B 创建模型文件，Round 1.5 运行 build_runner 生成），此时引用是正常的，不用担心编译报错。

---

### 3. 平台权限配置

#### Android：`ke_le_me/android/app/src/main/AndroidManifest.xml`

先读取现有文件，在 `<manifest>` 标签内（`<application>` 标签之前）添加：
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

#### iOS：`ke_le_me/ios/Runner/Info.plist`

先读取现有文件，在 `<dict>` 内添加：
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>渴了么需要获取您的位置来提供当地天气信息，以便为您推荐更准确的饮水量</string>
```

#### macOS entitlements（两个文件均需修改）

- `ke_le_me/macos/Runner/DebugProfile.entitlements`
- `ke_le_me/macos/Runner/Release.entitlements`

在两个文件的 `<dict>` 内各添加：
```xml
<key>com.apple.security.personal-information.location</key>
<true/>
```

---

## 重要约束

- 只修改上述列出的 6 处文件/位置
- 不要修改任何其他 lib/ 下的 Dart 文件
- 先用 Read 工具读取每个文件的当前内容，再做修改
- import 中的 adapter 类此时可能不存在，这是预期内的（另一个 agent 同步创建模型，Round 1.5 生成 adapter）
