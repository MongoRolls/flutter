# 规格：社区关怀

> 领域：backend + flutter · 版本：1.1.0 · 最后更新：2026-04-01

## 概述

社区关怀功能包含两个子模块：
1. **心心相连（关怀联系人）**：通过好友码添加关怀好友，相互发送"喝水了吗"提醒
2. **挑战广场（Plaza）**：加入标准化饮水挑战（7天、30天等），用连续打卡天数衡量进度

---

## 需求

### REQ-CARE-01：好友码

**描述**：每个用户拥有唯一的 6 字符好友码（字母表：`ABCDEFGHIJKLMNOPQRSTUVWXYZ23456789`，不含数字 0、1），可懒惰生成并支持轮换。

**场景 1：获取好友码**
- Given 用户已登录
- When GET `/api/care/friend-code`
- Then 返回当前好友码；若用户从未有过好友码，则自动生成一个 6 字符随机码并返回

**场景 2：轮换好友码**
- Given 用户希望更换好友码
- When POST `/api/care/friend-code/rotate`
- Then 生成不同于当前码的新码，更新到数据库，返回新码

**场景 3：并发生成安全**
- Given 多个并发请求同时尝试为同一用户生成好友码
- When 数据库 unique 约束冲突
- Then 使用 `updateMany + friendCode: null` 乐观锁策略，回退读取已生成的码，保证幂等

---

### REQ-CARE-02：好友查找

**描述**：通过好友码搜索对方，添加为关怀联系人。

**场景 1：查找好友**
- Given 用户输入 6 位好友码（大小写不敏感，忽略空格）
- When GET `/api/care/friend-lookup?code=XXXXXX`（需登录）
- Then 返回 `{ userId, nickname }`，HTTP 200

**场景 2：查找自己**
- Given 输入的好友码与当前用户自己的好友码相同
- When GET `/api/care/friend-lookup`
- Then 返回 400，错误消息"不能添加自己"

**场景 3：好友码不存在**
- Given 输入的好友码无对应用户
- When GET `/api/care/friend-lookup`
- Then 返回 404，错误码 `NOT_FOUND`

**场景 4：查找限流（防滥用）**
- Given 同一用户 60 秒内查找超过配置次数（`RATE_LIMIT_FRIEND_LOOKUP_USER_PER_MIN`，默认 12）
- When 再次查找
- Then 返回 429，响应头含 `Retry-After`

**场景 5：IP 维度限流**
- Given 同一 IP 60 秒内查找超过 `RATE_LIMIT_FRIEND_LOOKUP_IP_PER_MIN`（默认 40）次
- When 再次查找
- Then 返回 429（双桶策略：用户桶和 IP 桶均需检查；IP 桶超限后归还用户桶消耗点）

---

### REQ-CARE-03：关怀联系人管理

**场景 1：添加关怀联系人**
- Given 用户通过好友查找找到目标用户 ID，且当前 owner 下有效关怀联系人数 **少于 20**
- When POST `/api/care/contacts` 携带 `{ contactId, nickname }`
- Then upsert `CareContact` 记录，返回 201

**场景 1b：达到服务端人数上限**
- Given 当前用户作为 owner 已有 **20** 位不同的关怀联系人
- When POST `/api/care/contacts` 尝试新增第 21 位**不同**的 `contactId`
- Then 返回 **4xx** 校验错误（`ValidationError`），且不创建新记录

**场景 1c：仅更新备注昵称**
- Given 已存在 `(ownerId, contactId)` 的 `CareContact` 行
- When POST `/api/care/contacts` 仅更新 `nickname`
- Then 成功（不受 20 人上限阻塞）

**场景 2：查询联系人列表**
- Given 用户已登录
- When GET `/api/care/contacts`
- Then 返回所有关怀联系人列表，含联系人的 `id` 和 `nickname`

**场景 3：删除关怀联系人**
- Given 用户已有联系人记录
- When DELETE `/api/care/contacts/:id`
- Then 删除对应 `CareContact` 记录，返回 204

**场景 4：记录不属于当前用户**
- When DELETE `/api/care/contacts/:id`（该记录 `ownerId` ≠ 当前用户）
- Then 返回 404，错误码 `NOT_FOUND`

**场景 5：离线模式下使用本地缓存**
- Given 用户未登录或网络不可用
- When `HeartProvider` 加载联系人
- Then 从 SharedPreferences 本地缓存读取联系人列表

---

### REQ-CARE-04：发送关怀提醒

**场景 1：模板 + 后端发送**
- Given 用户在关怀页选择联系人与模板（`templateId` 1–4）
- When 客户端调用 `POST /api/care/remind` 且服务端校验通过
- Then 服务端持久化提醒（如 `CareReminder`）；客户端展示成功反馈（如 Toast）；**FCM/APNs 推送到对方设备**为后续阶段（见后端 README Phase 6）

**场景 2：关怀记录超 30 天自动清理**（若本地实现关怀时间线）
- Given `HeartProvider` 加载时检查关怀记录
- When 记录创建时间 > 30 天
- Then 自动从本地列表删除该记录

---

### REQ-CARE-06：好友饮水摘要（peers/hydration）

**描述**：owner 拉取已添加的关怀联系人在指定**本地日历日**的饮水摘要（`todayMl` / `dailyGoalMl` / `visible`）。

**场景 1：查询摘要**
- Given 用户已登录且存在关怀联系人
- When `GET /api/care/peers/hydration?date=YYYY-MM-DD&tzOffset=`（`tzOffset` 为分钟偏移，与 drink-logs 一致）
- Then 返回数组，每项含 `userId`、`todayMl`、`dailyGoalMl`、`visible`（`visible` 恒为 `true`，向关怀好友展示摘要）

---

### REQ-CARE-05：挑战广场

**描述**：预设标准化挑战，用户加入后通过连续打卡天数自动计算进度。

**场景 1：展示可用挑战**
- Given 用户打开广场 Tab
- When `PlazaProvider.refresh()` 被调用
- Then 返回挑战列表；挑战进度来源于 `UserProvider.streakDays`

**场景 2：加入挑战**
- Given 用户选择一个挑战
- When `PlazaProvider.joinChallenge(challenge)` 被调用
- Then 挑战状态更新为已加入，保存到 SharedPreferences

**场景 3：挑战完成判断**
- Given 用户连续打卡 streakDays 天
- When `PlazaProvider` 计算进度
- Then `challenge.isCompleted = streakDays >= challenge.targetDays`

**当前内置挑战（示例）**：

| 挑战名称       | 目标天数 | 描述                   |
|----------------|----------|------------------------|
| 7天铁人        | 7        | 连续 7 天达成每日目标  |
| 30天搭档计划   | 30       | 连续 30 天达成每日目标 |
| 5天早起水友    | 5        | 连续 5 天按时起床饮水  |

---

## API 端点

| 方法   | 路径                              | 认证 | 限流         | 说明                     |
|--------|-----------------------------------|------|--------------|--------------------------|
| GET    | `/api/care/contacts`              | 是   | —            | 获取关怀联系人列表       |
| POST   | `/api/care/contacts`              | 是   | —            | 添加/更新关怀联系人      |
| DELETE | `/api/care/contacts/:id`          | 是   | —            | 删除关怀联系人           |
| GET    | `/api/care/friend-code`           | 是   | —            | 获取/生成好友码          |
| POST   | `/api/care/friend-code/rotate`    | 是   | —            | 轮换好友码               |
| GET    | `/api/care/friend-lookup?code=`   | 是   | 双桶限流     | 通过好友码查找用户       |
| GET    | `/api/care/peers/hydration`       | 是   | —            | 关怀好友当日饮水摘要   |
| POST   | `/api/care/remind`                | 是   | —            | 向好友发送模板提醒     |

---

## 数据模型

### CareContact（Prisma）

| 字段        | 类型     | 约束                       | 说明              |
|-------------|----------|----------------------------|-------------------|
| `ownerId`   | String   | FK → User "owner"          | 关怀发起方         |
| `contactId` | String   | FK → User "contact"        | 被关怀对象         |
| `nickname`  | String   | 1-20 字符                  | 联系人备注昵称    |
| `createdAt` | DateTime | default now                | 添加时间          |

**唯一约束**：`[ownerId, contactId]`

### CareContact（本地 Dart 模型）

```dart
class CareContact {
  final String id;
  final String userId;    // 对方 userId
  final String nickname;
  final String? avatarEmoji;
}
```

### CareRecord（本地 Dart 模型，SharedPreferences）

```dart
class CareRecord {
  final String id;
  final String contactId;
  final String contactName;
  final DateTime time;
  final String message;
}
```

### Challenge（本地 Dart 模型）

```dart
class Challenge {
  final String id;
  final String title;
  final String description;
  final int targetDays;
  bool joined;
}
```

---

## 客户端实现路径

- **HeartProvider**：`flutter/lib/features/community/providers/heart_provider.dart`
- **PlazaProvider**：`flutter/lib/features/community/providers/plaza_provider.dart`
- **CommunityScreen**：`flutter/lib/features/community/screens/community_screen.dart`
- **BackendApiService**：`getCareContacts()`, `createCareContact()`, `getFriendCode()`, `rotateFriendCode()`, `lookupFriendCode()`, `getPeersHydration()`, `sendCareRemind()`
