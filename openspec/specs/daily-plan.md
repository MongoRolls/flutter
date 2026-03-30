# 规格：每日饮水计划

> 领域：backend + flutter · 版本：1.0.0 · 最后更新：2026-03-27

## 概述

每日饮水计划功能让 AI 根据用户体质、活动、天气，生成当日个性化的分时饮水时间表（8-12 个 Slot）。用户可按计划执行打卡，也可将计划总量设为今日目标。

---

## 需求

### REQ-PLAN-01：天气获取（计划前置）

**描述**：生成计划前需获取当前天气，支持 GPS 自动定位和手动输入城市两种方式。

**场景 1：GPS 自动获取天气**
- Given 用户进入计划页，未有今日计划
- When `PlanProvider.loadWeatherByGps()` 被调用
- Then 调用 `LocationService.getLocation()` 获取坐标，再调用 `WeatherService.getWeather(lat, lon)` 获取天气数据，更新 `PlanProvider.weatherData`

**场景 2：手动输入城市获取天气**
- Given 用户在输入框填写城市名称
- When 点击"获取天气"
- Then 调用 `WeatherService.geocodeCity(city)` 解析坐标，再获取天气，更新 `weatherData`

**场景 3：定位权限拒绝**
- Given 用户拒绝位置权限
- When GPS 获取失败
- Then `LocationService` 返回默认坐标（北京：39.9042, 116.4074），继续获取天气

**场景 4：天气获取失败**
- Given 网络不可用
- When 天气 API 调用失败
- Then 使用磁盘缓存的过期天气数据（stale-while-revalidate）；若无缓存，展示"天气获取失败"提示

---

### REQ-PLAN-02：AI 生成计划

**场景 1：正常生成计划**
- Given 已有今日天气数据
- When 用户点击"生成计划"，`PlanProvider.generatePlan()` 被调用
- Then 调用 `AiService.sendMessageStream()`（使用 `PlanPromptBuilder` 构建的 prompt），流式接收 AI 输出，完成后解析 JSON，创建 `TodayPlan` 并持久化到 Hive

**场景 2：Prompt 结构**
- When `PlanPromptBuilder` 构建 prompt
- Then 系统提示约束：纯 JSON 格式输出，含 `summary`、`totalMl`、`slots[]`（time, ml, note）；用户 prompt 包含：用户资料、活动类型、天气、作息时间、当前时间、已有摄入量

**场景 3：计划格式约束**
- Given AI 生成计划
- Then Slot 数量 8-12 个，所有 slot.ml 之和等于 `totalMl`，时间范围在起床时间至就寝前 30 分钟之间

**场景 4：今日已有计划（缓存命中）**
- Given Hive 中已存储今日 `TodayPlan`
- When 用户打开计划页
- Then 直接展示已有计划，不重新生成；用户可点击"重新生成"刷新

**场景 5：JSON 解析失败**
- Given AI 返回内容含非 JSON 前缀文字
- When `generatePlan()` 解析
- Then 提取 `{...}` 或 `[...]` 区块重新解析；仍失败则显示"计划生成失败，请重试"

---

### REQ-PLAN-03：Slot 打卡执行

**场景 1：标记 Slot 完成**
- Given 计划页展示当日 Slot 列表
- When 用户点击某个 Slot 的"记录"按钮
- Then 调用 `PlanProvider.logSlotDrink(slot)`，内部调用 `UserProvider.addDrink(slot.ml, ...)`，Slot 状态更新为已完成（✓），UI 即时反馈

**场景 2：已完成 Slot 不可重复打卡**
- Given Slot 已标记为 completed
- When 用户再次点击
- Then 按钮禁用或提示"已记录"

---

### REQ-PLAN-04：采纳计划目标

**场景 1：将计划 totalMl 设为今日目标**
- Given 计划已生成，`plan.totalMl` ≠ 当前 `dailyGoalMl`
- When 用户点击"设为今日目标"
- Then 调用 `PlanProvider.adoptAsGoal()`，更新 `UserProvider.profile.dailyGoalMl`，同步保存

---

### REQ-PLAN-05：计划提醒通知

**场景 1：为未来 Slot 调度通知**
- Given 计划生成完成
- When `PlanProvider.scheduleSlotReminders()` 被调用
- Then 为当日所有未完成且时间在未来的 Slot 调用 `NotificationService.scheduleCustomReminder()`，通知 ID 范围 1000-1019

**场景 2：重新生成计划时清除旧通知**
- Given 用户重置计划
- When `PlanProvider.reset()` 被调用
- Then 调用 `NotificationService.cancelPlanReminders()` 取消 ID 1000-1019 的所有通知，然后清除 Hive 中当日 `TodayPlan`

---

### REQ-PLAN-06：后端计划持久化

**描述**：TodayPlan 也同步到后端，支持未来多设备恢复。

**场景 1：保存计划到后端**
- Given 计划生成并写入 Hive 后
- When 用户已认证
- Then POST `/api/plans` 携带 `{ date, planJson }` 同步到服务端（upsert）

**场景 2：获取后端已有计划**
- Given 应用启动或用户换设备
- When GET `/api/plans?date=2026-03-27`
- Then 返回该日期的计划 JSON，或 null（如不存在）

---

## API 端点

| 方法 | 路径          | 认证 | 说明                         |
|------|---------------|------|------------------------------|
| GET  | `/api/plans`  | 是   | 查询指定日期计划（`?date=`） |
| POST | `/api/plans`  | 是   | 新建/更新计划（upsert）      |

---

## 数据模型

### TodayPlan（Prisma）

| 字段       | 类型     | 约束                         | 说明              |
|------------|----------|------------------------------|-------------------|
| `userId`   | String   | FK → User, indexed           | 所属用户          |
| `date`     | DateTime | @db.Date                     | 计划日期          |
| `planJson` | Json     | —                            | 完整计划对象      |

**唯一约束**：`[userId, date]`

### TodayPlan（Hive, typeId=3）

```dart
class TodayPlan extends HiveObject {
  String id;
  String date;            // "YYYY-MM-DD"
  String summary;         // AI 生成的计划摘要
  int totalMl;            // 计划总饮水量
  List<PlanSlot> slots;   // 时间段列表
  DateTime createdAt;
}

class PlanSlot {
  String time;            // "HH:mm"
  int ml;                 // 推荐量
  String note;            // 场景说明
  bool completed;         // 是否已打卡
}
```

### PlanPrompt 输出格式（AI 约束）

```json
{
  "summary": "今日计划摘要",
  "totalMl": 2200,
  "slots": [
    { "time": "07:30", "ml": 300, "note": "起床后补充水分" },
    { "time": "09:30", "ml": 200, "note": "上午工作间隙" }
  ]
}
```

---

## 客户端实现路径

- **PlanProvider**：`flutter/lib/features/plan/providers/plan_provider.dart`
- **PlanPromptBuilder**：`flutter/lib/features/plan/utils/plan_prompt_builder.dart`
- **PlanScreen**：`flutter/lib/features/plan/screens/plan_screen.dart`
- **TodayPlan 模型**：`flutter/lib/features/plan/models/today_plan.dart`
