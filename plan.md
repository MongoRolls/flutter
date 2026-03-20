# 渴了么 · MVP 新功能设计计划

> 原则：**不动现有代码**，只新增功能。服务端部分单独存档（见 server-plan.md）。

---

## 一、背景与目标

**原始 PRD 第四菜单页（暂定【社区】）**

> 主要为多喝水社区功能，目的通过趣味化、社交化的激励设计，将喝水从被动任务转化为主动打卡行为，大幅提升长期留存。
>
> - 挑战赛：搭子计划。连续一个月按时完成饮水计划，获得成就奖品
> - 心连心模块：提醒家人/好友多喝水（可监督），通知提醒可推送到对方app上

**MVP 范围**：只做 UI，本地 mock 数据，不依赖服务端。

---

## 二、新增 Tab 设计

现有导航（不改动）：
```
[ 首页 ] [ 安排 ] [ AI助手 ] [ 设置 ]
```

**新增一个 Tab**（插入到现有导航中）：

```
[ 首页 ] [ 安排 ] [ AI助手 ] [ 社区 ] [ 设置 ]
```

> 社区 Tab 整合「心连心」和「多喝水」两块内容，单屏滚动展示。

---

## 三、Tab：社区

> 整合心连心与多喝水两块内容，单屏滚动。

### 页面结构

```
[心连心]
  - 我的关怀圈
  - 发送关怀
  - 关怀足迹

[多喝水]
  - 我的打卡
  - 进行中的挑战
  - 发现挑战
  - 成就墙
```

---

### 心连心模块

> 完整参考 `心连心通知界面.html`，保留所有 UI 设计。

#### 页面结构

```
[我的关怀圈]
  - 联系人列表：头像 + 今日水量进度环 + 操作按钮
  - AI 温馨提示
  - + 添加关怀的人

[发送关怀]
  - 快选话术模板（2×2 网格，4 个预置）
  - 自定义消息输入框（含 AI 润色/表情按钮）
  - 收件人多选 Tag
  - 发送关怀按钮

[关怀足迹]
  - 时间线：你发出的 / 收到的 / AI自动触发的
  - 展示对方是否已回复
```

#### 联系人卡片

每个联系人：
- 头像（emoji + 渐变背景，按关系类型配色）
- 状态指示点：🟢 已完成 / 🟠 进行中 / 🔴 还没开始
- 姓名 + 关系（妈妈 / 爸爸 / 恋人 / 朋友）
- 今日饮水文字（如 `已喝 1600ml` / `仅喝了 800ml`）
- 水进度环（小型 SVG 圆环，颜色随百分比变化）
- 操作按钮：进度低 → `提醒喝水`（pulsing 动画）/ 进度好 → `发送爱心`

#### 话术模板（预置 4 个）

| 场景 | 文案 |
|---|---|
| ☀️ 午后提醒 | 下午了，多喝水，我惦记你 |
| 🌙 睡前关怀 | 睡前喝点水，好梦 |
| 💪 运动补水 | 刚运动完，记得补水！ |
| 🌡️ 天气提醒 | 今天这么热，多喝水哦 |

#### 通知交互（本地模拟）

收到关怀通知时，通知操作按钮：
- **`💧 已喝了！`** → 触发一次喝水记录
- **`发送回心`** → 打开快速回复面板

发送关怀时 → 调用现有 `NotificationService` 触发本地通知（服务端版本替换为真实推送）

#### 本地数据存储

```
SharedPreferences:
  care_contacts   → List<CareContact> JSON
  care_records    → List<CareRecord> JSON（近 30 天）

mock 策略：
  联系人水量 → 每日随机生成（在合理范围内波动）
  不需要对方真实 app，全部本地模拟
```

---

### 多喝水模块

> 偏 Duolingo「挑战+成就」感，但保持极简。**不做联赛排行榜**。

#### 页面结构

```
[我的打卡]
  - 当前连续打卡天数（streak 火焰展示）
  - 本周完成情况（7格日历点）

[进行中的挑战]
  - 搭子计划 / 当前挑战的进度卡片

[发现挑战]
  - 挑战卡片列表（可参与的挑战）

[成就墙]（简版）
  - 已解锁成就展示（收藏感）
```

#### 打卡展示

- 火焰 🔥 + 数字：`连续 7 天`
- 今天未打卡时，火焰变灰 + 轻微抖动提示
- 本周 7 格：已完成=蓝色水滴，未完成=空圈，今天=特殊高亮

> 复用 `UserProvider` 里现有的 streak 数据，**不改动任何现有逻辑**。

#### 挑战类型（MVP 预置 3 种）

| 挑战 | 说明 | 时长 | 奖励 |
|---|---|---|---|
| 🤝 搭子计划 | 邀请好友组队，共同每日达标 | 30 天 | 「搭子勋章」 |
| 🔥 铁人挑战 | 连续 7 天每天 100% 完成 | 7 天 | 「铁人勋章」 |
| 🌅 早起补水 | 连续 5 天 8 点前喝第一杯 | 5 天 | 「晨型人勋章」 |

挑战卡片展示：
- 挑战名 + 简介
- 进度条（`已完成 X / 目标 Y 天`）
- 奖励勋章预览
- `参与挑战` / `已参与`（本地状态）

#### 成就墙（简版）

- 6~8 个成就格子
- 已解锁 → 彩色 + 解锁日期
- 未解锁 → 灰色模糊（知道存在但看不清）
- 解锁时弹出庆祝动画（参考 Duolingo 成就解锁效果）

**MVP 预置成就（基于本地真实数据自动解锁）**：

| 成就 | 触发条件 |
|---|---|
| 💧 初心一滴 | 第一次喝水记录 |
| 🔥 一周连击 | 连续达标 7 天 |
| 🌊 月度坚持 | 连续达标 30 天 |
| ❤️ 首次关怀 | 第一次发送心连心关怀 |
| 🤝 搭子精神 | 完成搭子计划挑战 |
| 🏆 铁人 | 完成铁人挑战 |

---

## 四、数据模型（新增，不改动现有模型）

### CareContact

```dart
class CareContact {
  final String id;
  final String name;
  final String relationship; // 'mom' | 'dad' | 'partner' | 'friend'
  final String avatarEmoji;
  final int mockDailyGoalMl;  // mock，服务端版本删除
  int mockTodayMl;            // 每日随机生成
}
```

### CareRecord

```dart
class CareRecord {
  final String id;
  final String fromLabel;   // '你' 或联系人名
  final String toLabel;
  final String message;
  final DateTime sentAt;
  final bool isReplied;
  final String? replyText;
}
```

### Achievement

```dart
class Achievement {
  final String id;
  final String title;
  final String iconEmoji;
  final String description;
  final bool isUnlocked;
  final DateTime? unlockedAt;
}
```

### Challenge

```dart
class Challenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int durationDays;
  final String rewardBadgeId;
  bool isJoined;
  int currentProgress;  // 本地计算
}
```

---

## 五、Provider（新增）

```
lib/features/community/providers/heart_provider.dart
lib/features/community/providers/plaza_provider.dart
```

### HeartProvider
- CRUD 联系人（存 SharedPreferences）
- 发送关怀（触发本地通知 + 存 CareRecord）
- 每日刷新 mock 联系人水量数据

### PlazaProvider
- 管理挑战列表（预置 mock）
- 跟踪挑战进度（监听 UserProvider 的 streak / todayMl）
- 成就解锁逻辑（监听 UserProvider + HeartProvider 数据）
- 预留 `Future<void> syncToServer()` 空实现

---

## 六、文件结构（新增部分）

```
lib/features/
  community/
    screens/
      community_screen.dart
      add_contact_screen.dart
    widgets/
      care_contact_card.dart
      water_ring_mini.dart
      care_template_chip.dart
      care_timeline_item.dart
      streak_display.dart
      challenge_card.dart
      achievement_badge.dart
    providers/
      heart_provider.dart
      plaza_provider.dart
    models/
      care_contact.dart
      care_record.dart
      achievement.dart
      challenge.dart
```

---

## 七、不在 MVP 范围内（明确排除）

- ❌ 联赛排行榜
- ❌ XP / 积分系统改造
- ❌ 现有首页/安排/AI助手/设置 Tab 修改
- ❌ 好友实时同步（需服务端）
- ❌ 跨设备推送（需服务端）
- ❌ 手表/手环同步（需服务端）
- ❌ 吉祥物角色

---

## 八、服务端预留（另存，后续开发）

| 功能 | 对应 API |
|---|---|
| 心连心跨设备推送 | POST /care/send |
| 好友关系管理 | GET/POST /friends |
| 好友实时水量 | WebSocket /friends/water-status |
| 搭子计划组队 | POST /challenges/invite |
| 成就云同步 | POST /sync/achievements |

Provider 中预留空方法，UI 层无需改动，上线服务端后替换实现即可。

---

## 九、开发顺序

1. 数据模型 + Provider（CareContact, CareRecord, Achievement, Challenge）
2. 社区 Tab — 心连心模块（完整按 HTML 稿实现）
3. 社区 Tab — 多喝水模块（打卡展示 → 挑战卡片 → 成就墙）
4. 导航接入（在 main_shell.dart 加入社区 Tab）
5. 动效打磨（成就解锁、发送关怀反馈）
