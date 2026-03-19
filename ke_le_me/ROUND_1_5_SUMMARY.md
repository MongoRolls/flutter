# Round 1.5 构建步骤总结

**日期**：2026-03-19  
**目标**：为 Hive 模型生成 TypeAdapter，并使项目通过 `flutter analyze` 零错误。

---

## 执行步骤

### Step 1：`flutter pub get`

```
Exit code: 0
Got dependencies!
19 packages have newer versions incompatible with dependency constraints.
```

所有依赖正常解析。有 19 个包存在不兼容的更新版本（不影响构建，忽略）。

---

### Step 2：`dart run build_runner build --delete-conflicting-outputs`

```
Exit code: 0
Succeeded after 2.8s with 9 outputs (85 actions)
```

**生成的文件（3 个 TypeAdapter）：**

| 文件 | Hive typeId | 对应模型 |
|------|------------|---------|
| `lib/core/models/memory_fact.g.dart` | 0 | `MemoryFactAdapter` |
| `lib/core/models/session_summary.g.dart` | 1 | `SessionSummaryAdapter` |
| `lib/core/models/custom_reminder.g.dart` | 2 | `CustomReminderAdapter` |

> **注意（非阻断性警告）**：`hive_generator` 报告当前 `analyzer` 版本（6.4.1）低于最新（12.0.0），语言版本支持为 3.4.0 vs SDK 的 3.11.0。不影响代码生成正确性；在 V2 依赖升级阶段可一并处理。

---

### Step 3：`flutter analyze`（初次运行）

发现 **4 个编译错误**，均来自 V2 新增的 tool_handler 文件引用了尚未在既有文件中实现的成员：

| # | 错误 | 文件 | 缺失成员 |
|---|------|------|---------|
| 1 | `undefined_method` | `tool_handlers/reminder_tools.dart:49` | `NotificationService.scheduleCustomReminder()` |
| 2 | `undefined_getter` | `tool_handlers/weather_tools.dart:13` | `UserProvider.weatherData` |
| 3 | `undefined_getter` | `tool_handlers/weather_tools.dart:33` | `UserProvider.goalPrediction` |
| 4 | `undefined_getter` | `tool_handlers/weather_tools.dart:34` | `UserProvider.dynamicGoalMl` |

---

### Step 4：修复编译错误

**修改 1：`lib/core/services/notification_service.dart`**

新增 `scheduleCustomReminder()` 方法：
- 参数：`id`、`title`、`scheduledDate`、`repeat`（none/daily/weekly）
- 使用 `tz.TZDateTime.from()` 转换时区
- `repeat == 'daily'` → `matchDateTimeComponents: DateTimeComponents.time`
- `repeat == 'weekly'` → `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`

**修改 2：`lib/core/providers/user_provider.dart`**

- 新增 import：`weather_data.dart`、`goal_predictor.dart`
- 新增私有字段：`_weatherData`、`_goalPrediction`、`_dynamicGoalMl`
- 新增公开 getter：`weatherData`、`goalPrediction`、`dynamicGoalMl`

> **原则**：仅添加编译所需的最小接口（字段初始为 null），不实现任何业务逻辑。实际的天气获取、目标计算逻辑将在后续 Round 中由 `WeatherService`、`LocationService`、`GoalPredictor` 填充。

---

### Step 5：`flutter analyze`（修复后）

```
Analyzing ke_le_me...
No issues found! (ran in 3.6s)
```

**零错误，零警告。**

---

## 产物清单

```
新增文件（build_runner 生成）：
  ke_le_me/lib/core/models/memory_fact.g.dart
  ke_le_me/lib/core/models/session_summary.g.dart
  ke_le_me/lib/core/models/custom_reminder.g.dart

修改文件（编译修复）：
  ke_le_me/lib/core/services/notification_service.dart
    + scheduleCustomReminder() 方法
  ke_le_me/lib/core/providers/user_provider.dart
    + import WeatherData, GoalPrediction
    + _weatherData / _goalPrediction / _dynamicGoalMl 字段
    + weatherData / goalPrediction / dynamicGoalMl getter
```

---

## 当前状态

| 检查项 | 状态 |
|--------|------|
| `flutter pub get` | ✅ 通过 |
| `build_runner` TypeAdapter 生成 | ✅ 3 个文件生成 |
| `flutter analyze` | ✅ 零错误 |
| V2 预期缺失成员（已注明为 TODO） | N/A（已通过 stub 解决编译） |

---

## 下一步（Round 2）

根据 `v2.md` 计划，Round 2 将实现：
- `LocationService`：geolocator 定位 + 权限处理
- `WeatherService`：Open-Meteo API + 30min 缓存 + Completer 去重
- `UserProvider` 接入 WeatherService + GoalPredictor（填充上述 stub 的实际逻辑）
- `main.dart` 注册 Hive boxes（`memory_facts`、`session_summaries`、`custom_reminders`）
