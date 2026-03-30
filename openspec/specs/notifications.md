# 规格：通知系统

> 领域：flutter · 版本：1.0.0 · 最后更新：2026-03-27

## 概述

通知系统通过 `flutter_local_notifications` 驱动，提供三类本地推送：
1. **定期水提醒**：按用户作息时间和间隔，每天在起床到就寝之间定期推送
2. **自定义提醒**：由 AI 或用户手动设置的一次性/周期性提醒
3. **关怀通知**：社区功能中向关怀联系人发出"喝水了吗"即时通知

所有通知均为本地通知，无需网络，不依赖推送服务。

---

## 需求

### REQ-NOTIF-01：权限管理

**场景 1：请求通知权限**
- Given 应用首次运行或在设置页开启通知
- When `NotificationService.requestPermission()` 被调用
- Then iOS/macOS 弹出系统权限对话框；Android 13+ 请求 `POST_NOTIFICATIONS` 权限

**场景 2：权限被拒绝**
- Given 用户拒绝通知权限
- When 保存设置时
- Then `notificationsEnabled` 仍可设为 true（存储态），但通知不会实际出现；UI 不报错

---

### REQ-NOTIF-02：定期水提醒调度

**描述**：在 [起床时间, 就寝时间] 内，每隔 `reminderIntervalMin` 分钟调度一次提醒，预排未来 7 天。

**场景 1：正常调度**
- Given 用户已完成 onboarding 且 `notificationsEnabled = true`
- When 应用启动或 `NotificationService.scheduleReminders(...)` 被调用
- Then 先取消所有旧通知，然后为接下来 7 天每个时间点调度一条 `zonedSchedule` 通知

**场景 2：提醒语气（reminderStyle）**
- Given `reminderStyle = "gentle"` / `"lively"` / `"serious"`
- When 生成通知文案
- Then 从对应语气的消息列表中随机选取一条

**场景 3：跨时区调度**
- Given 设备在不同时区
- When 计算通知触发时间
- Then 使用 `timezone` + `flutter_timezone` 确保通知在设备本地时间触发

**场景 4：重新调度（设置变更后）**
- Given 用户修改了起床时间、就寝时间、提醒间隔或提醒语气
- When `UserProvider.saveProfile()` 被调用
- Then 调用 `NotificationService.scheduleReminders(...)` 以新参数重新调度

**场景 5：Onboarding 期间不调度**
- Given `UserProfile.onboardingCompleted = false`
- When 应用启动
- Then 不调度任何提醒

---

### REQ-NOTIF-03：自定义提醒（AI / 计划 Slot）

**描述**：AI 或计划 Slot 可设置带特定时间的自定义提醒，支持 none / daily / weekly 重复。

**场景 1：创建自定义提醒**
- Given AI 调用 `set_reminder` 工具，或计划 `scheduleSlotReminders()` 被执行
- When `NotificationService.scheduleCustomReminder(id, title, datetime, repeat)` 被调用
- Then 使用 `matchDateTimeComponents` 为指定时间调度通知

**场景 2：重复类型**
- Given `repeat = "none"`：仅在指定 datetime 触发一次
- Given `repeat = "daily"`：每天同一时刻触发（`matchDateTimeComponents.time`）
- Given `repeat = "weekly"`：每周同一天同一时刻触发（`matchDateTimeComponents.dayOfWeekAndTime`）

**场景 3：取消 AI 设置的提醒**
- Given AI 调用 `cancel_reminder` 工具
- When 处理器调用 `NotificationService.cancel(notificationId)`
- Then 对应通知被取消

**场景 4：计划重置时清除 Slot 提醒**
- Given 用户重置今日计划
- When `PlanProvider.reset()` 执行
- Then `NotificationService.cancelPlanReminders()` 取消 ID 1000-1019 范围的所有通知

---

### REQ-NOTIF-04：关怀通知

**场景 1：发送关怀通知**
- Given 用户在社区页对关怀联系人发出"喝水了吗"提醒
- When `HeartProvider.sendCare(contact)` 被调用
- Then `NotificationService.showCareNotification(title, body)` 立即弹出本地通知

> 注：当前关怀通知为本地通知（仅在发送方设备上显示），联系人接收功能为未来规划。

---

### REQ-NOTIF-05：通知 ID 分配规则

| 范围        | 用途               |
|-------------|--------------------|
| 0 - 999     | 定期水提醒（7天 × N个/天）|
| 1000 - 1019 | 计划 Slot 提醒      |
| 2000+       | AI 自定义提醒       |
| 9000+       | 关怀通知            |

---

## 平台差异

| 平台    | 特殊要求                                                              |
|---------|-----------------------------------------------------------------------|
| iOS     | 运行时请求权限；沙盒限制通知数量                                      |
| macOS   | 需要 `com.apple.security.network.client` 权限用于时区数据下载         |
| Android | Android 13+ 需 `POST_NOTIFICATIONS` 权限；精确闹钟需 `SCHEDULE_EXACT_ALARM` |

---

## 数据模型

### CustomReminder（Hive, typeId=2）

| 字段             | 类型      | 说明                                       |
|------------------|-----------|--------------------------------------------|
| `id`             | String    | UUID                                       |
| `title`          | String    | 提醒标题                                   |
| `datetime`       | DateTime  | 触发时间                                   |
| `repeat`         | String    | none \| daily \| weekly                   |
| `notificationId` | int       | 系统通知 ID                                |
| `active`         | bool      | 是否启用                                   |

---

## 客户端实现路径

- **NotificationService**：`flutter/lib/core/services/notification_service.dart`
  - `init()`, `requestPermission()`, `scheduleReminders()`, `scheduleCustomReminder()`, `cancelPlanReminders()`, `showCareNotification()`
- **CustomReminder 模型**：`flutter/lib/core/models/custom_reminder.dart`
- **调用方**：`UserProvider.saveProfile()`, `PlanProvider.scheduleSlotReminders()`, `HeartProvider.sendCare()`
