# 规格：天气与智能目标

> 领域：flutter · 版本：1.0.0 · 最后更新：2026-03-27

## 概述

天气模块从 Open-Meteo（免费 API，无需 Key）获取实时天气，通过 Nominatim 实现反向地理编码。`GoalPredictor` 将天气数据与用户体质结合，计算动态推荐饮水量，在首页以卡片形式展示。

---

## 需求

### REQ-WEATHER-01：天气数据获取

**场景 1：从 GPS 获取天气（默认路径）**
- Given 应用启动或 `UserProvider._loadWeatherAndGoal()` 被调用
- When `LocationService.getLocation()` 返回坐标
- Then 调用 `WeatherService.getWeather(lat, lon)` 获取天气数据，更新 `UserProvider.weatherData`

**场景 2：三级缓存策略**
- Level 1（内存缓存）：若内存中的 `_cache` 存在且未过期（30分钟内），直接返回
- Level 2（磁盘缓存）：若内存缓存过期，读取 SharedPreferences 中存储的 JSON；若数据未过期则返回，同时更新内存缓存
- Level 3（网络请求）：调用 Open-Meteo API 获取新数据，写入内存和磁盘缓存

**场景 3：网络失败降级**
- Given 网络请求失败
- When 磁盘缓存中有过期（stale）数据
- Then 返回过期数据并标记为降级（用户可能看到旧天气）

**场景 4：并发请求合并**
- Given 同时有多个调用者请求天气
- When 第一个请求正在进行中
- Then 后续请求通过 `Completer` 等待同一个网络请求完成，避免重复请求

---

### REQ-WEATHER-02：地理编码

**场景 1：GPS 坐标 → 城市名（反向地理编码）**
- Given 已获取用户 GPS 坐标
- When `WeatherService.reverseGeocode(lat, lon)` 被调用
- Then 调用 Nominatim API（OpenStreetMap），返回中文城市名；失败时返回 null

**场景 2：城市名 → 坐标（正向地理编码）**
- Given 用户在计划页手动输入城市名称
- When `WeatherService.geocodeCity(city)` 被调用
- Then 调用 Open-Meteo Geocoding API，返回第一个匹配的 `{ lat, lon }`；未找到返回 null

**场景 3：位置权限拒绝时默认坐标**
- Given 定位服务不可用或用户拒绝权限
- When `LocationService.getLocation()` 失败
- Then 返回北京默认坐标（39.9042, 116.4074），继续获取天气

---

### REQ-WEATHER-03：天气数据字段

**描述**：使用 Open-Meteo Current Weather + Daily API。

| 字段名称         | 来源                  | 说明                              |
|------------------|-----------------------|-----------------------------------|
| `temperature`    | current.temperature_2m | 当前气温（°C）                   |
| `humidity`       | current.relative_humidity_2m | 相对湿度（%）               |
| `apparentTemp`   | current.apparent_temperature | 体感温度（°C）              |
| `weatherCode`    | current.weather_code  | WMO 天气码（映射为中文描述/emoji）|
| `uvIndexMax`     | daily.uv_index_max[0] | 当日最高 UV 指数                 |
| `tempMax`        | daily.temperature_2m_max[0] | 当日最高温（°C）           |
| `tempMin`        | daily.temperature_2m_min[0] | 当日最低温（°C）           |
| `fetchedAt`      | 本地时间戳            | 用于缓存过期判断（30分钟）        |

---

### REQ-WEATHER-04：WMO 天气码映射

**场景 1：天气码 → 中文描述**
- When `WeatherData.weatherDescription` getter 被调用
- Then 根据 WMO 天气码返回中文描述：

| 范围      | 描述示例                  |
|-----------|---------------------------|
| 0         | 晴天                      |
| 1-3       | 大部晴朗 / 部分多云 / 阴天 |
| 45, 48    | 雾                        |
| 51-57     | 毛毛雨                    |
| 61-65     | 小雨 / 中雨 / 大雨        |
| 71-77     | 小雪 / 中雪 / 大雪        |
| 80-82     | 阵雨                      |
| 95        | 雷雨                      |

---

### REQ-WEATHER-05：AI 动态目标预测

**描述**：`GoalPredictor` 是纯函数模块，基于天气和体质计算个性化饮水目标。

**场景 1：预测目标计算**
- Given 已知 `weightKg`、`activityLevel`、`WeatherData`
- When `GoalPredictor.predict(weather, profile)` 被调用
- Then 按以下规则计算：

**基础量**：`weightKg × 35` ml

**天气调整系数**：

| 条件                    | 调整值       |
|-------------------------|-------------|
| 温度 > 35°C             | +400 ml      |
| 温度 25-35°C            | +200 ml      |
| 湿度 < 30%              | +150 ml      |
| UV 指数 > 8             | +200 ml      |
| UV 指数 5-8             | +100 ml      |

**活动水平系数**：

| 活动水平      | 系数    |
|---------------|---------|
| sedentary     | ×1.0    |
| light         | ×1.1    |
| moderate      | ×1.2    |
| active        | ×1.35   |
| very_active   | ×1.5    |

**结果范围**：clamp 到 [1500, 5000] ml

**场景 2：返回 GoalPrediction 对象**
- Given 预测完成
- When 调用 `predict()` 返回
- Then 包含 `{ predictedMl, factors: Map<String, int>, explanation: String }`
  - `factors` 记录每项调整量（用于展示分解说明）
  - `explanation` 是一句人可读的中文解释

**场景 3：首页展示 AI 推荐**
- Given `UserProvider.dynamicGoal` 与当前 `dailyGoalMl` 不同
- When `WeatherGoalCard` 渲染
- Then 展示 AI 推荐目标、差值和因素说明，提供"采纳"按钮

**场景 4：天气数据不可用时**
- Given `UserProvider.weatherData = null`
- When `WeatherGoalCard` 渲染
- Then 显示加载中或"天气数据不可用"，不展示 AI 推荐目标

---

## 数据模型

### WeatherData（Dart 模型）

```dart
class WeatherData {
  final double temperature;
  final double humidity;
  final double apparentTemp;
  final int weatherCode;
  final double uvIndexMax;
  final double tempMax;
  final double tempMin;
  final DateTime fetchedAt;

  bool get isExpired => DateTime.now().difference(fetchedAt).inMinutes > 30;
  String get weatherDescription => /* WMO 码 → 中文 */;
}
```

**缓存 Key（SharedPreferences）**：`weather_cache_{lat}_{lon}`

### GoalPrediction（Dart 模型）

```dart
class GoalPrediction {
  final int predictedMl;
  final Map<String, int> factors;   // e.g. {"高温": 200, "活跃": 350}
  final String explanation;          // e.g. "根据今日气温和你的活动量，建议饮水 2600ml"
}
```

---

## 外部 API 依赖

| 服务          | URL 模板                                                  | 用途               | Key 需求 |
|---------------|-----------------------------------------------------------|-------------------|----------|
| Open-Meteo    | `https://api.open-meteo.com/v1/forecast`                  | 天气数据获取       | 无需     |
| Open-Meteo    | `https://geocoding-api.open-meteo.com/v1/search`          | 城市名 → 坐标      | 无需     |
| Nominatim     | `https://nominatim.openstreetmap.org/reverse`             | GPS → 城市名       | 无需     |

---

## 客户端实现路径

- **WeatherService**：`flutter/lib/core/services/weather_service.dart`
  - `getWeather()`, `reverseGeocode()`, `geocodeCity()`
- **LocationService**：`flutter/lib/core/services/location_service.dart`
  - `getLocation()`（低精度，10 秒超时，失败返回北京坐标）
- **GoalPredictor**：`flutter/lib/core/utils/goal_predictor.dart`
  - `predict(weather, profile)` → `GoalPrediction`
- **WeatherData 模型**：`flutter/lib/core/models/weather_data.dart`
- **WeatherGoalCard**：`flutter/lib/features/home/widgets/weather_goal_card.dart`
- **调用入口**：`UserProvider._loadWeatherAndGoal()`, `PlanProvider.loadWeatherByGps()`
