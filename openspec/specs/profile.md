# 规格：用户资料

> 领域：backend + flutter · 版本：1.0.0 · 最后更新：2026-03-27

## 概述

用户资料包含两层：
- **User 表**：身份信息（nickname）
- **UserProfile 表**：健康与偏好设置（饮水目标、作息、提醒方式、身体数据）

资料在本地（SharedPreferences）持久化，异步推送到后端同步。

---

## 需求

### REQ-PROFILE-01：获取资料

**场景 1：已认证用户获取资料**
- Given 用户已登录
- When GET `/api/profile`
- Then 返回 `{ user: { id, nickname, email, createdAt }, profile: { dailyGoalMl, wakeTime*, bedTime*, reminderIntervalMin, reminderStyle, notificationsEnabled, weightKg, activityLevel } }`，HTTP 200

**场景 2：UserProfile 记录不存在（新用户）**
- Given 用户已注册但未保存过 Profile
- When GET `/api/profile`
- Then `profile` 字段为 null，HTTP 200

---

### REQ-PROFILE-02：更新资料

**描述**：支持部分更新，所有字段均为可选。`nickname` 更新 User 表；其余字段 upsert UserProfile 表。

**场景 1：更新饮水目标**
- Given 用户已登录
- When PUT `/api/profile` 携带 `{ dailyGoalMl: 2500 }`
- Then UserProfile 中 `dailyGoalMl` 更新为 2500，返回 200

**场景 2：更新昵称**
- Given 用户已登录
- When PUT `/api/profile` 携带 `{ nickname: "小水友" }`
- Then User 表中 `nickname` 更新，返回 200

**场景 3：字段验证失败**
- Given `dailyGoalMl` 超出范围（<500 或 >10000）
- When PUT `/api/profile`
- Then 返回 400，错误码 `VALIDATION_ERROR`

**场景 4：首次写入 Profile（upsert）**
- Given 用户尚无 UserProfile 记录
- When PUT `/api/profile` 携带任意合法字段
- Then 自动创建 UserProfile 记录，返回 200

---

### REQ-PROFILE-03：本地资料管理

**描述**：客户端以 SharedPreferences 为本地真相，后端同步为异步旁路。

**场景 1：加载资料**
- Given 应用启动
- When `UserProvider.loadProfile()` 被调用
- Then 优先从 SharedPreferences 读取；如已认证，异步向后端同步（`PUT /api/profile`）

**场景 2：保存资料（设置页修改）**
- Given 用户在设置页修改了任意字段
- When `UserProvider.saveProfile()` 被调用
- Then 立即写入 SharedPreferences，异步推送到 `PUT /api/profile`；失败不阻塞 UI

---

### REQ-PROFILE-04：日摄水量目标

**描述**：支持手动设置和 AI 推荐两种目标来源。

**场景 1：手动设置目标**
- Given 用户在设置页手动输入每日目标
- When 保存
- Then `UserProfile.dailyGoalMl` 更新，HomeScreen 进度环同步刷新

**场景 2：采纳 AI 推荐目标**
- Given `WeatherGoalCard` 展示了 AI 推荐值，与当前目标不同
- When 用户点击"采纳"按钮
- Then 调用 `UserProvider.adoptDynamicGoal()`，目标更新为 AI 推荐值

**场景 3：推荐目标计算规则**
- Given 已知 weightKg、activityLevel、当前天气（温度/湿度/UV）
- When `GoalPredictor.predict()` 被调用
- Then 基础量 = weightKg × 35ml，结合天气/活动系数综合调整，结果夹在 [1500, 5000]ml 区间内

---

## API 端点

| 方法 | 路径           | 认证 | 说明               |
|------|----------------|------|--------------------|
| GET  | `/api/profile` | 是   | 获取用户资料       |
| PUT  | `/api/profile` | 是   | 更新资料（部分更新）|

---

## 数据模型

### UserProfile（Prisma）

| 字段                  | 类型     | 约束 / 默认值                                                      | 说明             |
|-----------------------|----------|--------------------------------------------------------------------|------------------|
| `userId`              | String   | unique, FK → User                                                  | 关联用户         |
| `dailyGoalMl`         | Int      | [500, 10000]，default 2000                                         | 每日饮水目标     |
| `wakeTimeHour`        | Int      | [0, 23]，default 7                                                 | 起床时 (小时)    |
| `wakeTimeMinute`      | Int      | [0, 59]，default 0                                                 | 起床时 (分钟)    |
| `bedTimeHour`         | Int      | [0, 23]，default 23                                                | 就寝时 (小时)    |
| `bedTimeMinute`       | Int      | [0, 59]，default 0                                                 | 就寝时 (分钟)    |
| `reminderIntervalMin` | Int      | [15, 240]，default 60                                              | 提醒间隔（分钟） |
| `reminderStyle`       | String   | gentle \| lively \| serious，default gentle                        | 提醒语气         |
| `notificationsEnabled`| Boolean  | default true                                                       | 通知总开关       |
| `weightKg`            | Float?   | [20, 300]                                                          | 体重（kg）       |
| `activityLevel`       | String?  | sedentary \| light \| moderate \| active \| very_active            | 活动水平         |

### UserProfile（本地 SharedPreferences）

| Key               | 类型    | 说明                        |
|-------------------|---------|-----------------------------|
| `user_profile`    | String  | UserProfile 序列化 JSON      |
| `today_date`      | String  | 今日日期字符串（日归档用）   |
| `today_ml`        | Int     | 今日累计饮水量               |
| `today_logs`      | String  | 今日饮水记录 JSON 数组       |

---

## 客户端实现路径

- **UserProvider**：`flutter/lib/core/providers/user_provider.dart`
- **UserProfile 模型**：`flutter/lib/core/models/user_profile.dart`
  - `recommendedGoal` getter：weight × 35，夹在 [1500, 4000]
  - 序列化：`toMap()` / `fromMap()`
- **GoalPredictor**：`flutter/lib/core/utils/goal_predictor.dart`
