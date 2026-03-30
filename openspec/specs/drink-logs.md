# 规格：饮水记录与离线同步

> 领域：backend + flutter · 版本：1.0.0 · 最后更新：2026-03-27

## 概述

饮水记录是核心业务数据。客户端以 **本地优先** 方式写入，后台异步同步到服务端。支持离线场景：网络不可用时入队，恢复后批量重试。

---

## 需求

### REQ-DRINK-01：添加饮水记录

**描述**：用户通过首页快捷按钮或自定义量记录一次饮水。

**场景 1：正常添加**
- Given 用户在首页点击"喝水"并选择或输入水量
- When `UserProvider.addDrink(ml, type, desc)` 被调用
- Then 立即更新本地 `today_ml` 和 `today_logs`，进度环动画刷新；异步 POST `/api/drink-logs`

**场景 2：今日目标达成触发庆祝动画**
- Given 添加后 `today_ml >= dailyGoalMl`
- When 记录写入完成
- Then HomeScreen 触发目标达成动画（bounce 效果）

**场景 3：网络失败时入队**
- Given POST `/api/drink-logs` 请求失败
- When 后台重试
- Then 调用 `DrinkSyncService.enqueuePendingLog(...)` 将记录写入离线队列（SharedPreferences）

**场景 4：日期跨天检测**
- Given 用户跨越午夜后首次调用 `addDrink` 或 `loadProfile`
- When 检测到 `today_date` ≠ 当前日期
- Then 将昨日 `today_ml` 归档到 `history_{date}` 和 `monthly_hits_{year}_{month}`，重置 `today_ml = 0`，`today_logs = []`

---

### REQ-DRINK-02：查询饮水记录

**描述**：后端支持按日期或日期范围查询，客户端也可本地读取今日记录。

**场景 1：查询指定日期记录**
- Given 请求携带 `?date=2026-03-27&tzOffset=480`
- When GET `/api/drink-logs`
- Then 返回该日期（考虑时区偏移）的所有记录，含 `totalMl` 和 `count`

**场景 2：查询日期范围**
- Given 请求携带 `?startDate=2026-03-01&endDate=2026-03-31`
- When GET `/api/drink-logs`
- Then 返回范围内所有记录，limit 默认 100，最大 500

**场景 3：本地今日记录（不调后端）**
- Given 应用已加载
- When HomeScreen 渲染饮水日志列表
- Then 直接从 `UserProvider.todayLogs` 读取（SharedPreferences 中的 `today_logs`）

---

### REQ-DRINK-03：删除饮水记录

**场景 1：删除单条记录（后端）**
- Given 日志 ID 属于当前用户
- When DELETE `/api/drink-logs/:id`
- Then 删除对应记录，返回 204

**场景 2：日志不属于当前用户或不存在**
- When DELETE `/api/drink-logs/:id`
- Then 返回 404，错误码 `NOT_FOUND`

---

### REQ-DRINK-04：离线批量同步

**描述**：Flutter 客户端在启动时或网络恢复时，将离线队列的记录批量上传到服务端。

**场景 1：批量同步成功**
- Given 离线队列中有 N 条记录（N ≤ 500）
- When `DrinkSyncService.syncPendingQueue()` 被调用
- Then POST `/api/drink-logs/bulk-sync` 一次性上传，服务端返回 `{ synced, idMap }`

**场景 2：去重处理**
- Given 服务端已存在相同 `loggedAt + ml` 组合的记录
- When 批量同步
- Then 服务端跳过重复记录，仅插入新记录

**场景 3：idMap 映射本地 ID**
- Given 服务端返回 `idMap: [{ localId, serverId }]`
- When 客户端处理响应
- Then 可用于将本地生成的临时 ID 映射到服务端真实 ID（当前版本暂不强制使用）

**场景 4：重试策略**
- Given 批量同步请求失败
- When `syncPendingQueue()` 重试
- Then 指数退避，最多重试 3 次；超过 `maxRetries=5` 次的记录移入失败队列 `failed_pending_logs`

**场景 5：批量同步条数限制**
- Given 离线队列超过 500 条
- When POST `/api/drink-logs/bulk-sync`
- Then 返回 400（超出单次上限，客户端应分批发送）

---

### REQ-DRINK-05：月度历史同步（拉取）

**描述**：每次启动时从服务端拉取当月饮水数据，合并到本地月度统计。

**场景 1：正常拉取并合并**
- Given 用户已认证
- When `DrinkSyncService.syncMonthlyLogs()` 被调用
- Then 从 GET `/api/drink-logs?startDate=&endDate=` 拉取本月数据，按天聚合，以 max 策略合并到本地 `monthly_hits_*`

**场景 2：网络不可用**
- Given 无网络连接
- When 拉取失败
- Then 静默忽略，使用本地缓存数据展示月历

---

## API 端点

| 方法   | 路径                          | 认证 | 说明                        |
|--------|-------------------------------|------|-----------------------------|
| GET    | `/api/drink-logs`             | 是   | 查询记录（日期/范围/分页）  |
| POST   | `/api/drink-logs`             | 是   | 创建单条记录                |
| POST   | `/api/drink-logs/bulk-sync`   | 是   | 批量同步（最多 500 条）     |
| DELETE | `/api/drink-logs/:id`         | 是   | 删除单条记录                |

---

## 数据模型

### DrinkLog（Prisma）

| 字段          | 类型      | 约束 / 默认值              | 说明              |
|---------------|-----------|----------------------------|-------------------|
| `id`          | String    | PK, cuid                   | 记录唯一 ID       |
| `userId`      | String    | FK → User, indexed         | 所属用户          |
| `ml`          | Int       | [1, 5000]                  | 饮水量（ml）      |
| `icon`        | String    | default "💧"               | 显示图标（emoji） |
| `description` | String    | default "喝水"             | 描述文本          |
| `loggedAt`    | DateTime  | default now()              | 记录时间          |
| `syncedAt`    | DateTime? | —                          | 服务端同步时间    |

**复合索引**：`[userId, loggedAt]`

### DrinkLog（本地 SharedPreferences）

| Key                         | 类型   | 说明                        |
|-----------------------------|--------|-----------------------------|
| `today_logs`                | String | 今日记录 JSON 数组           |
| `monthly_hits_{year}_{month}` | String | 月度 day→totalMl Map       |
| `history_{date}`            | String | 历史单日总量（用于连续打卡）  |
| `pending_drink_logs`        | String | 离线队列 JSON 数组           |
| `failed_pending_logs`       | String | 永久失败队列 JSON 数组       |

### DrinkLog（本地 Dart 模型）

```dart
class DrinkLog {
  final String time;        // "HH:mm"
  final String icon;        // emoji
  final String description;
  final int ml;
}
```

### PendingDrinkLog（离线队列条目）

```dart
{
  "localId":    String,  // 本地生成的临时 ID
  "ml":         int,
  "icon":       String,
  "description":String,
  "loggedAt":   String,  // ISO 8601
  "retryCount": int,
  "createdAt":  String   // ISO 8601
}
```

---

## 连续打卡（Streak）计算

**规则**：从今天起向前连续计算每天是否达成 `dailyGoalMl`。

- 数据来源：`history_{date}` keys（保留 365 天）
- 今日算入：当 `today_ml >= dailyGoalMl` 时，今日也计入连续天数
- 中断：任意一天数据不存在或 totalMl < dailyGoalMl，连续中断

---

## 客户端实现路径

- **UserProvider**：`flutter/lib/core/providers/user_provider.dart`
  - `addDrink()`, `loadProfile()`, `_syncDrinkLogs()`
- **DrinkSyncService**：`flutter/lib/core/services/drink_sync_service.dart`
  - `syncMonthlyLogs()`, `enqueuePendingLog()`, `syncPendingQueue()`
- **BackendApiService**：`flutter/lib/core/services/backend_api_service.dart`
  - `createDrinkLog()`, `getDrinkLogs()`, `bulkSyncDrinkLogs()`
