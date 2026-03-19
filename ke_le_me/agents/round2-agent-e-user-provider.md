# Round 2 · Agent E — UserProvider + ChatStorageService

**并行组**：Round 2（与 Agent F、G、H 同时执行，Round 1 已全部完成）  
**前提条件**：Round 1 的所有新文件已创建，build_runner 已运行生成 `*.g.dart`  
**负责文件**：
- `lib/core/providers/user_provider.dart`（修改）
- `lib/features/chat/services/chat_storage_service.dart`（修改）

**注意**：只修改上述 2 个文件，不要碰其他任何文件

---

你正在为 Flutter 项目「渴了么」(ke_le_me/) 实施 V2 升级的 Round 2。Round 1 已经完成了所有新文件的创建（WeatherData、MemoryFact、SessionSummary、CustomReminder 模型，LocationService、WeatherService、MemoryService、GoalPredictor 服务）。你的任务是修改 UserProvider 和 ChatStorageService。

## 1. 修改 UserProvider

**路径**：`lib/core/providers/user_provider.dart`

先用 Read 工具读取现有完整文件内容。

### 新增 import

在文件顶部新增：
```dart
import '../models/weather_data.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../utils/goal_predictor.dart';
```

### 新增私有字段

在类的字段区域（`_profile`、`_todayMl` 等附近）新增：
```dart
WeatherData? _weatherData;
int? _dynamicGoalMl;
GoalPrediction? _goalPrediction;
```

### 新增 getter

在现有 getter 区域（`profile`、`todayMl` 等附近）新增：
```dart
WeatherData? get weatherData => _weatherData;
int? get dynamicGoalMl => _dynamicGoalMl;
GoalPrediction? get goalPrediction => _goalPrediction;
```

### 修改 loadProfile()

在现有 `loadProfile()` 方法末尾的 `notifyListeners()` 调用**之前**，插入一行：
```dart
// 异步加载天气和动态目标（不阻塞主流程）
_loadWeatherAndGoal();
```

完整的末尾结构应为：
```dart
// 加载月度打卡和连续天数
_loadMonthlyHits(prefs);
_computeStreak(prefs);

// 异步加载天气和动态目标（不阻塞主流程）
_loadWeatherAndGoal();

notifyListeners();
```

### 新增方法

在类的末尾（`}` 之前）新增以下 3 个方法：

```dart
Future<void> _loadWeatherAndGoal() async {
  try {
    final location = await LocationService.instance.getCurrentLocation();

    // 缓存位置坐标
    if (!location.isDefault) {
      _profile.cachedLat = location.lat;
      _profile.cachedLon = location.lon;
      saveProfile();
    }

    _weatherData = await WeatherService.instance.getWeather(
      location.lat,
      location.lon,
    );

    _goalPrediction = GoalPredictor.predict(
      weightKg: _profile.weight,
      activityLevel: _profile.activityLevel,
      weather: _weatherData,
    );
    _dynamicGoalMl = _goalPrediction!.predictedMl;

    notifyListeners();
  } catch (e) {
    debugPrint('Failed to load weather/goal: $e');
    _dynamicGoalMl = _profile.dailyGoalMl;
    notifyListeners();
  }
}

/// 用户一键采纳 AI 建议目标
void adoptDynamicGoal() {
  if (_dynamicGoalMl != null && _dynamicGoalMl != _profile.dailyGoalMl) {
    _profile.dailyGoalMl = _dynamicGoalMl!;
    saveProfile();
    notifyListeners();
  }
}

/// 手动刷新天气和动态目标
Future<void> refreshWeather() async {
  await _loadWeatherAndGoal();
}
```

---

## 2. 修改 ChatStorageService

**路径**：`lib/features/chat/services/chat_storage_service.dart`

先用 Read 工具读取现有完整文件内容。

### 新增 import

在文件顶部新增：
```dart
import 'package:hive/hive.dart';
import '../../../core/models/session_summary.dart';
```

### 修改 addSummary() 方法

找到现有的 `addSummary(String summary)` 方法，在其末尾（`await prefs.setString(...)` 之后）追加 Hive 写入逻辑：

```dart
Future<void> addSummary(String summary) async {
  // 保留现有 SharedPreferences 逻辑（兼容性）
  final prefs = await SharedPreferences.getInstance();
  final summaries = await getSummaries();
  summaries.add(summary);
  if (summaries.length > _maxSummaries) {
    summaries.removeRange(0, summaries.length - _maxSummaries);
  }
  await prefs.setString(_summariesKey, jsonEncode(summaries));

  // V2: 同时写入 Hive SessionSummary box
  try {
    final box = Hive.box<SessionSummary>('session_summaries');
    final sessionSummary = SessionSummary(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      summary: summary,
      date: DateTime.now(),
      topics: [],
    );
    await box.put(sessionSummary.id, sessionSummary);

    // Hive 上限 30 条，超出则删除最旧的
    if (box.length > 30) {
      final sorted = box.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      for (var i = 0; i < box.length - 30; i++) {
        await sorted[i].delete();
      }
    }
  } catch (e) {
    debugPrint('Failed to save summary to Hive: $e');
  }
}
```

---

## 重要约束

- 只修改上述 2 个文件，不要碰其他文件
- 保留所有现有逻辑不变，只做增量添加
- `WeatherData`、`LocationService`、`WeatherService`、`GoalPredictor`、`SessionSummary` 均已在 Round 1 创建，import 路径：
  - `../models/weather_data.dart`
  - `../services/location_service.dart`
  - `../services/weather_service.dart`
  - `../utils/goal_predictor.dart`
  - `../../../core/models/session_summary.dart`（相对于 chat_storage_service.dart）
- `debugPrint` 需要 `import 'package:flutter/foundation.dart';`（如果 user_provider.dart 中还没有）
- 完成后运行 `flutter analyze` 检查这两个文件是否有错误
