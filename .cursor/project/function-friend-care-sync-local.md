# 组队挑战「非实时」同步 + 本地提醒

> 文档类型：产品方案（非已实现代码）。范围：Flutter + backend；不含 `web/`。
> 文件名待改为 `function-team-challenge-sync-local.md`（当前为历史遗留命名）。

---

## 0. 产品边界（必读）

| 类别 | 是否做 | 说明 |
|------|--------|------|
| **队员互提醒** | **不做** | 不含：队员 A 向队员 B 发「喝水提醒 / 打卡 / 私信式问候」、点对点收件箱、未读角标里「某人叫你」、针对单人的跟进本地通知。代码库中若已有 `TeamCheckIn`/收件箱草稿，应下线或冻结。 |
| **组队挑战提醒** | **可做** | 用户已参与**组队挑战**时，对**挑战本身**做非实时同步 + 本地排程提醒（进度、截止临近、结算等），文案围绕**挑战目标与期限**，不冒充「队友正在叫你」。 |

---

## 0.1 分步落地说明

| Step | 做什么 | 产出 / 检查点 |
|------|--------|----------------|
| **1** | **语义收口** | UI/通知/埋点不出现「队友叫你打卡」「向好友发起打卡」等点对点话术。 |
| **2** | **数据域** | Prisma 迁移加 `Challenge`、`ChallengeMember` 表（见 §6.1.1）；进度复用现有 `DrinkLog`，**不新增**「发给某用户的提醒记录」表。 |
| **3** | **HTTP** | `GET /api/challenges/mine`（拉取）+ `POST /api/challenges`（创建）+ 加入/退出/结果确认（见 §6.1.3）；**不提供**「向 toUserId 发提醒」类写入。 |
| **4** | **客户端** | 登录/回前台调 `syncTeamChallenges()`；`scheduleXxx` 仅绑定 **challengeId + reminderKind**，不绑定「来自某 nickname 的未读」。 |
| **5** | **通知 Channel / ID** | 「组队挑战」独立 Channel；id 段 `9100–9109`（与喝水定时提醒分离）。 |
| **6** | **设置** | 用户可关「组队挑战提醒」总开关；关闭后取消已排程的挑战类本地通知。 |

---

## 0.2 挑战生命周期（状态枚举）

通知排程与进度展示的所有条件判断以此为基础，状态由**服务端计算**后返回，客户端不自行推断：

| 状态 | 条件 | 客户端可排通知类型 |
|------|------|------------------|
| `upcoming` | `now < periodStart` | 无（挑战未开始） |
| `active` | `periodStart ≤ now ≤ periodEnd` | 「今日进度」「截止临近」 |
| `ended` | `now > periodEnd`，等待服务端结算 | 「等待结算」（低优先，可选） |
| `settled` | 服务端已结算，积分/徽章已计算 | 「查看结果」（若 `resultAcknowledgedAt == null`） |

---

## 1. 产品目标

**核心问题**：在不依赖远程推送（FCM / APNs）的前提下，如何让用户及时感知**已参与的组队挑战**状态，并愿意回到 App？

**解法**：
- 用户**打开 App 登录后**，拉取「我参与的挑战」及进度摘要（增量，见 §6.1.3 `since` 语义）。
- 对**仍需行动或即将发生节点**的挑战，在本地排程**轻量提醒**，不冒充实时推送。

**设计原则**：
1. **诚实**：文案写「挑战」「截止」「团队进度」，不写「队友此刻在催你」。
2. **轻量**：聚合优于轰炸，组队挑战类本地通知每天上限 2 条（与「喝水定时提醒」分 Channel、分计数）。
3. **可取消**：挑战结束、用户退出、或设置关闭后，取消该挑战已排程的后续本地通知。

---

## 2. 功能设计

### 2.1 同步触发时机

| 时机 | 行为 | 备注 |
|------|------|------|
| **冷启动 / 登录成功** | 拉取「我参与的挑战」增量（`since=lastChallengeSyncAt`） | 必须实现 |
| **从后台回前台** | 节流后再拉一次 | 冷却 20 分钟，可配置 |
| **打卡成功后** | 触发一次轻量挑战进度拉取（见 §2.4 闭环） | 冷却 60 秒 |

### 2.2 拉取后客户端处理流程

```
拉取结果
  ├─ 写本地缓存：lastChallengeSyncAt、activeChallenges[]
  ├─ 无待关注状态 → 仅刷新挑战列表，不排新通知
  └─ 有待关注状态
        ├─ 按 §2.6 规则计算角标数
        ├─ 更新挑战列表高亮
        └─ 按 §2.3 规则调度本地通知
             └─ 条件消失 → 取消 challengeId + reminderKind 对应槽位
```

**本地缓存字段**：

```
activeChallenge {
  challengeId          string
  title                string
  status               enum      // upcoming | active | ended | settled
  role                 enum      // leader | member
  goalType             string    // individual_daily | team_total
  goalValue            int
  periodEnd            timestamp
  teamProgress         int       // 团队已累计（单位与 goalType 一致）
  selfContributed      boolean   // 今日是否已贡献（服务端计算后返回）
  resultAcknowledgedAt timestamp?  // null = 结算结果未查看
  lastEventAt          timestamp   // 服务端最新变更时间（用于增量判断）
}
```

### 2.3 组队挑战提醒策略

通知对象：**挑战事件**，不是「某位队员」。

#### 触发规则与文案

| 提醒类型 | 触发条件 | 排程时间 | 文案方向 |
|----------|----------|----------|----------|
| **今日进度** | `status == active && selfContributed == false` | `bedTime - 1h`，默认 20:00 | 「「{挑战名}」今天还没打卡，帮团队冲一冲～」 |
| **截止临近** | `status == active && periodEnd - now < 24h` | 立即排程至 `periodEnd - 2h` | 「「{挑战名}」即将截止，去看看团队进度」 |
| **查看结果** | `status == settled && resultAcknowledgedAt == null` | 拉取成功后 +5 分钟 | 「「{挑战名}」已结算，查看本期成绩」 |

#### 同一挑战同一天多类型触发时的优先级

```
优先级：查看结果 > 截止临近 > 今日进度

同一挑战同一天：
  • 「查看结果」触发 → 只排「查看结果」，取消/不排其他类型
  • 「截止临近」+「今日进度」同时触发 → 合并为一条：
    「「{挑战名}」今天截止，还没打卡，快去冲～」
  • 只有一类触发 → 按各自文案排一条
```

**多挑战时**：合并为一条摘要（「你有 2 个组队挑战需要留意」），每天上限 2 条。

### 2.4 selfContributed 闭环（打卡 → 取消通知）

`selfContributed` 由**服务端计算**，客户端不本地推断。

**触发链**：

```
用户打卡（DrinkLog 写入成功）
  └─ 打卡回调触发轻量拉取（节流 60s）
        └─ GET /api/challenges/mine?localDate=YYYY-MM-DD
              └─ 服务端返回最新 selfContributed
                    └─ 若 selfContributed == true
                          └─ 取消该 challengeId「今日进度」槽位通知
```

### 2.5 取消排程与设置

| 操作 | 效果 |
|------|------|
| 打卡后 `selfContributed` 变 true | 取消该挑战的「今日进度」通知 |
| 退出挑战 / 挑战解散 | 取消该挑战**所有类型**已排通知；清空本地缓存 |
| 查看结算结果 | 取消「查看结果」通知；本地写 `resultAcknowledgedAt` + `POST .../result-ack` |
| 设置关闭「组队挑战提醒」 | 取消所有 `9100–9109` 范围内已排通知 |

**Notification ID 规则**：`9100 + challengeIndex × 3 + kindOffset`
（kindOffset：今日进度 = 0，截止临近 = 1，查看结果 = 2）

### 2.6 挑战列表与角标

**角标计数规则**（满足以下任一条件的挑战数）：
- `status == active && selfContributed == false`（今日未打卡）
- `status == settled && resultAcknowledgedAt == null`（有未查看结算）

| 项目 | 推荐方案 | 说明 |
|------|----------|------|
| **角标** | 待处理挑战数（按上述规则），超过 9 显示 9+ | 与点对点社交收件箱区分 |
| **列表** | 每挑战一行：名称、进度摘要、截止相对时间 | 进行中优先 → 截止近者优先；已结束沉底 |

### 2.7 时间展示规则（近细远粗）

| 区间 | 展示 | 示例 |
|------|------|------|
| **≤ 24h** | 相对时间 | 「约 3 小时后截止」「今晚」 |
| **24～72h** | 自然日 | 「明天截止」「后天」 |
| **> 72h** | 月-日 | 「4 月 2 日结束」 |

---

## 3. 挑战创建与加入流程

> 前置依赖——没有创建/加入，「我参与的挑战」列表永远为空。

### 3.1 创建挑战

1. 发起方（队长）在 App 内填写：挑战名称、目标类型与值（如「7 天每日达到个人喝水目标」）、开始/结束日期。
2. 提交后服务端创建挑战，生成 6 位 **邀请码**（复用 `generateUniqueFriendCode` 随机码逻辑）。
3. 创建者自动成为 `leader`。

### 3.2 加入挑战

1. 受邀方在 App 内输入邀请码 → `POST /api/challenges/join`。
2. 服务端校验：挑战未结束（`status != ended / settled`）、人数未超上限（产品定）、未重复加入。
3. 加入后挑战出现在「我的挑战」列表。

### 3.3 退出挑战

- `active` 期间可退出；队长退出时若有其他成员，自动转让给最早加入的成员；无其他成员则挑战解散。
- 退出后客户端取消所有该挑战本地通知，清空缓存。

---

## 4. 边界与异常

| 场景 | 处理 |
|------|------|
| 挑战解散 / 用户被移出 | 服务端标记，下次同步时客户端清缓存 + 取消通知 |
| 挑战开始后邀请码失效 | 服务端拒绝加入（`status != upcoming`） |
| 时区 / 跨日 | 「今日是否已贡献」以用户本地自然日为准；客户端传 `localDate`，服务端存 UTC |
| 卸载重装 | 全量拉取参与关系；按服务端状态重算是否排程 |
| 多设备 | 以服务端状态为准；去重 key 含 `challengeId + reminderKind + utcDate` |
| 挑战人数剩 1 人 | 服务端可选自动解散或允许独自完成（产品定） |

---

## 5. 方案评估

### 优势

| 项 | 说明 |
|----|------|
| 工程成本可控 | 无 FCM/APNs；复用 HTTP + 本地通知 |
| 社交压力低 | 无「已读」「谁催谁」链路，减少隐私与压力争议 |
| 与产品边界一致 | 提醒绑定挑战规则与时间，不绑定点对点骚扰 |

### 约束与取舍

| 约束 | 影响 | 缓解 |
|------|------|------|
| **非实时** | 必须打开 App 或打卡才能刷新状态并补排提醒 | 文案诚实；用「截止」「今日」而非「刚刚」 |
| **本地通知精度** | 受系统省电策略影响 | 与现有喝水提醒同级预期 |
| **不做队员互提醒** | 无法通过产品内「拍一拍队友」提升互动 | 若未来需要，需单独 PRD 与合规/骚扰评审 |

---

## 6. 技术可行性

### 6.1 后端迁移（详细）

#### 6.1.1 Prisma Schema 变更

`User` 模型新增两条关系（紧接 `caredBy` 后）：

```prisma
  challenges        ChallengeMember[]
  createdChallenges Challenge[]       @relation("creator")
```

文件末尾追加：

```prisma
model Challenge {
  id          String   @id @default(cuid())
  title       String
  goalType    String   @default("individual_daily") // individual_daily | team_total
  goalValue   Int      // ml（individual_daily: 每日个人目标；team_total: 团队累计目标）
  periodStart DateTime
  periodEnd   DateTime
  status      String   @default("upcoming") // upcoming | active | ended | settled
  inviteCode  String   @unique
  creatorId   String
  creator     User     @relation("creator", fields: [creatorId], references: [id], onDelete: Cascade)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  members     ChallengeMember[]

  @@index([status])
  @@index([creatorId])
}

model ChallengeMember {
  id                   String    @id @default(cuid())
  challengeId          String
  challenge            Challenge @relation(fields: [challengeId], references: [id], onDelete: Cascade)
  userId               String
  user                 User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  role                 String    @default("member") // leader | member
  joinedAt             DateTime  @default(now())
  leftAt               DateTime? // 非 null 表示已退出
  resultAcknowledgedAt DateTime? // 用户查看结算结果的时间

  @@unique([challengeId, userId])
  @@index([userId])
  @@index([challengeId, leftAt]) // 筛选当前有效成员
}
```

#### 6.1.2 迁移文件

路径：`backend/prisma/migrations/20260330000002_add_team_challenge/migration.sql`

```sql
-- CreateTable: Challenge
CREATE TABLE "Challenge" (
    "id"          TEXT         NOT NULL,
    "title"       TEXT         NOT NULL,
    "goalType"    TEXT         NOT NULL DEFAULT 'individual_daily',
    "goalValue"   INTEGER      NOT NULL,
    "periodStart" TIMESTAMP(3) NOT NULL,
    "periodEnd"   TIMESTAMP(3) NOT NULL,
    "status"      TEXT         NOT NULL DEFAULT 'upcoming',
    "inviteCode"  TEXT         NOT NULL,
    "creatorId"   TEXT         NOT NULL,
    "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"   TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Challenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable: ChallengeMember
CREATE TABLE "ChallengeMember" (
    "id"                   TEXT         NOT NULL,
    "challengeId"          TEXT         NOT NULL,
    "userId"               TEXT         NOT NULL,
    "role"                 TEXT         NOT NULL DEFAULT 'member',
    "joinedAt"             TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt"               TIMESTAMP(3),
    "resultAcknowledgedAt" TIMESTAMP(3),
    CONSTRAINT "ChallengeMember_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Challenge_inviteCode_key"
    ON "Challenge"("inviteCode");
CREATE INDEX "Challenge_status_idx"
    ON "Challenge"("status");
CREATE INDEX "Challenge_creatorId_idx"
    ON "Challenge"("creatorId");
CREATE UNIQUE INDEX "ChallengeMember_challengeId_userId_key"
    ON "ChallengeMember"("challengeId", "userId");
CREATE INDEX "ChallengeMember_userId_idx"
    ON "ChallengeMember"("userId");
CREATE INDEX "ChallengeMember_challengeId_leftAt_idx"
    ON "ChallengeMember"("challengeId", "leftAt");

-- AddForeignKey
ALTER TABLE "Challenge"
    ADD CONSTRAINT "Challenge_creatorId_fkey"
    FOREIGN KEY ("creatorId") REFERENCES "User"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ChallengeMember"
    ADD CONSTRAINT "ChallengeMember_challengeId_fkey"
    FOREIGN KEY ("challengeId") REFERENCES "Challenge"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ChallengeMember"
    ADD CONSTRAINT "ChallengeMember_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
```

**执行命令**（`backend/` 目录下）：

```bash
npx prisma migrate dev --name add_team_challenge   # 开发
npx prisma migrate deploy                          # 生产
```

#### 6.1.3 API 接口规范

所有接口落在新建的 `challenges.routes.ts`（不污染 `care.routes.ts`），在 `app.ts` 注册到 `/api/challenges`。

---

**创建挑战**

```
POST /api/challenges
Body: { title, goalType, goalValue, periodStart, periodEnd }
```

- 服务端生成 6 位 `inviteCode`（复用 `generateUniqueFriendCode` 逻辑）
- 创建者自动成为 `leader`，写入 `ChallengeMember`
- 返回挑战详情含 `inviteCode`

---

**加入挑战**

```
POST /api/challenges/join
Body: { inviteCode: string }
```

- 校验：`status` 为 `upcoming` 或 `active`；人数未超上限；未重复加入；不能加入自己创建的
- 返回挑战摘要

---

**拉取我的挑战（增量）**

```
GET /api/challenges/mine?since=ISO_TIMESTAMP&localDate=YYYY-MM-DD
```

- `since`：上次同步时间；服务端返回 `updatedAt > since` **或** 成员 `leftAt/resultAcknowledgedAt` 有变更的挑战。首次拉取（`since` 缺省）返回全量。
- `localDate`：客户端本地日期（用于计算 `selfContributed`）；缺省时服务端用 UTC 当日兜底。

服务端对每条挑战额外计算：
- `selfContributed`：`localDate` 对应的 UTC 区间内，当前用户 `DrinkLog` 总量 ≥ `goalValue`
- `teamProgress`：当期所有活跃成员 `DrinkLog` 汇总
- `status`：当前生命周期状态（服务端实时计算）

```json
// 200 OK
{
  "items": [
    {
      "challengeId": "cm...",
      "title": "7 天喝水挑战",
      "status": "active",
      "role": "leader",
      "goalType": "individual_daily",
      "goalValue": 2000,
      "periodEnd": "2026-04-06T15:59:59.000Z",
      "teamProgress": 4500,
      "selfContributed": false,
      "resultAcknowledgedAt": null,
      "lastEventAt": "2026-03-30T10:00:00.000Z"
    }
  ],
  "syncedAt": "2026-03-30T12:00:00.000Z"
}
```

---

**查看挑战详情**

```
GET /api/challenges/:id
```

返回完整成员列表与进度明细（供详情页使用）。

---

**退出挑战**

```
POST /api/challenges/:id/leave
```

- 写入 `leftAt`；队长退出且有其他成员时自动转让给最早加入的 `member`；无其他成员时挑战解散（写 `status = ended`）

---

**确认结算结果**

```
POST /api/challenges/:id/result-ack
```

- 写入 `ChallengeMember.resultAcknowledgedAt`
- 客户端收到 200 后取消「查看结果」通知，本地更新 `resultAcknowledgedAt`

#### 6.1.4 Service 层关键逻辑

新建 `challenges.service.ts`（风格与现有 `care.service.ts` 一致）：

```typescript
// 创建挑战（含邀请码生成，复用 generateUniqueFriendCode）
export async function createChallenge(userId: string, data: CreateChallengeDto)

// 通过邀请码加入
export async function joinChallenge(userId: string, inviteCode: string)

// 拉取我的挑战（增量，含进度计算）
export async function getMyChallenge(userId: string, since?: Date, localDate?: string)

// 挑战详情（含成员进度）
export async function getChallengeDetail(userId: string, challengeId: string)

// 退出（含队长转让逻辑）
export async function leaveChallenge(userId: string, challengeId: string)

// 确认结算
export async function ackResult(userId: string, challengeId: string)
```

`selfContributed` 计算示例（在 `getMyChallenge` 内）：

```typescript
// localDate 由客户端传入（YYYY-MM-DD），换算为 UTC 区间
const { start, end } = localDateToUtcRange(localDate ?? utcToday())
const todayMl = await prisma.drinkLog.aggregate({
  where: { userId, loggedAt: { gte: start, lte: end } },
  _sum: { ml: true },
})
const selfContributed = (todayMl._sum.ml ?? 0) >= challenge.goalValue
```

#### 6.1.5 与现有代码对接点

| 文件 | 改动 | 内容 |
|------|------|------|
| `prisma/schema.prisma` | 新增 | `Challenge`、`ChallengeMember` 模型 + `User` 两条反向关系 |
| `prisma/migrations/…` | 新增 | `20260330000002_add_team_challenge/migration.sql` |
| `src/routes/challenges.routes.ts` | **新建** | 创建/加入/拉取/详情/退出/结果确认 |
| `src/services/challenges.service.ts` | **新建** | 6 个 service 函数 |
| `src/app.ts` | 修改 | 注册 `challenges.routes.ts` 到 `/api/challenges` |
| `src/middleware/rate-limit.ts` | 新增 | 邀请码查询限流（复用 `friendLookupRateLimit` 逻辑） |

### 6.2 Flutter 客户端

| 项 | 可行性 | 说明 |
|----|--------|------|
| 登录后同步 | 可行 | `MainShell` / 相关 Provider 在登录后调 `syncTeamChallenges()` |
| 打卡后更新 | 可行 | `DrinkLog` 写入回调触发轻量拉取（节流 60s） |
| 本地排程 | 可行 | `scheduleTeamChallengeReminder(challengeId, kind, fireAt, body)` |
| 取消 | 可行 | 按 `challengeId + kind` 批量 `cancelReminder`（id 段见 §2.5） |
| 与喝水提醒隔离 | 可行 | 独立 Channel + id 段 `9100–9109` |
| 结果确认 | 可行 | 进入结果页时 `POST .../result-ack` + 取消对应通知 |

### 6.3 本地数据过渡

- 挑战状态以**服务端为真相源**；本地仅存展示缓存与已排程 token，便于去重与取消。
- 若现有代码中有 `HeartProvider` 存储旧关怀字段，与挑战缓存保持独立键名，不合并。

---

## 7. 实现优先级

| 阶段 | 内容 | 产出 |
|------|------|------|
| **P0** | 后端 `Challenge + ChallengeMember` 迁移 + 创建/加入/拉取接口 | 挑战可创建、可加入、可展示 |
| **P1** | 打卡与挑战进度关联（`selfContributed` 计算）+ 挑战详情页 | 「参与 → 打卡 → 进度」闭环 |
| **P2** | 本地提醒（今日进度/截止临近/查看结果）+ 结果确认 + 设置开关 | 提醒闭环 |
| **P3** | 回前台节流、摘要合并通知、角标精细化、边界文案 | 体验精细化 |

**MVP 决策建议**：
- 提醒文案**永远**以挑战名为锚，不出现「某某队友让你喝水」。
- 明确**不做**点对点收件箱与向 `toUserId` 发提醒。
- `goalType` 初期只支持 `individual_daily`（最简），`team_total` P1 后追加。

---

## 8. 小结

| 维度 | 结论 |
|------|------|
| **产品定位** | 非实时同步**组队挑战**状态 + 对挑战节点的本地提醒；**不做**队员互提醒。 |
| **体验核心** | 诚实（挑战/截止/进度）、轻量（频控 + 摘要）、可关闭。 |
| **技术路径** | 新建 `Challenge/ChallengeMember` 表 + `challenges.routes.ts`；进度复用 `DrinkLog`；客户端按 `challengeId + kind` 排程与取消。 |
| **上线风险** | 低社交压力路径；本地通知触发率受机型影响（与喝水提醒同等预期）。 |

---

*文档版本：2026-03-30 v8 · 补全：挑战创建/加入流程（§3）、selfContributed 闭环（§2.4）、通知优先级与合并规则（§2.3）、角标判断规则（§2.6）、结算去重 flag `resultAcknowledgedAt`（§2.2/§2.5）、挑战生命周期状态枚举（§0.2）、完整 Prisma Schema + Migration SQL + API 规范（§6.1）。文件名待改为 `function-team-challenge-sync-local.md`。范围：Flutter + backend，不含 `web/`。*
