# KeLeME 后端架构计划

> Express.js 后端，为渴了么 Flutter 客户端提供 AI 代理、用户系统、数据同步和社区功能。

---

## 1. 核心问题

| 优先级 | 问题 | 现状 | 后端方案 |
|--------|------|------|---------|
| **P0** | API Key 暴露 | `ai_config.dart` 硬编码 DeepSeek Key，客户端直连 | 后端做 AI Proxy，Key 只存服务端 |
| **P0** | 数据无法跨设备 | 全部 SharedPreferences + Hive，换设备数据丢失 | 云端同步 |
| **P1** | 社区是 mock 的 | `PlazaProvider` / `HeartProvider` 全本地 | 真实社交后端 |
| **P1** | 无用户系统 | 没有登录/注册 | Auth 系统 |
| **P2** | 服务端推送 | 只有本地通知 | Push notification + 智能提醒 |

---

## 2. 技术栈

| 层 | 选型 | 理由 |
|----|------|------|
| Runtime | Node.js 20+ LTS | 稳定长期支持 |
| Language | TypeScript | 强类型，减少 bug |
| Framework | Express.js 4.x | 成熟稳定，生态丰富 |
| Database | PostgreSQL | 关系型，适合用户/日志/社交数据，聚合查询强 |
| ORM | Prisma | 类型安全，schema-first，迁移管理好 |
| Cache | Redis | session 黑名单、rate limiting、排行榜缓存 |
| Auth | JWT | access + refresh 双 token，移动端友好 |
| AI Proxy | SSE streaming 转发 | 直接转发 DeepSeek API，服务端注入 Key |
| Validation | Zod | 请求校验与 TypeScript 类型联动 |
| Push | Firebase Cloud Messaging | 跨平台推送 |
| API Style | RESTful | 简单清晰，匹配 Flutter dio |
| Logging | Pino | 高性能 JSON logger |
| Testing | Vitest + Supertest | 快速，TypeScript 原生支持 |
| Deploy | Docker → Railway / Fly.io / VPS | 容器化部署 |
| CI/CD | GitHub Actions | 自动化测试和部署 |

---

## 3. 项目结构

```
backend/
├── prisma/
│   ├── schema.prisma              # 数据库 schema
│   └── migrations/                # 自动生成的迁移
├── src/
│   ├── index.ts                   # 入口：启动 Express
│   ├── app.ts                     # Express 实例配置 (middleware)
│   ├── config/
│   │   └── env.ts                 # 环境变量加载 & Zod 校验
│   ├── middleware/
│   │   ├── auth.ts                # JWT 鉴权
│   │   ├── rate-limit.ts          # 限流 (尤其 AI 接口)
│   │   ├── validate.ts            # Zod schema 校验
│   │   └── error-handler.ts       # 全局错误处理
│   ├── routes/
│   │   ├── auth.routes.ts         # 注册 / 登录 / 刷新
│   │   ├── user.routes.ts         # 用户档案
│   │   ├── drink.routes.ts        # 饮水记录
│   │   ├── ai.routes.ts           # AI 聊天 + 计划 (SSE proxy)
│   │   ├── community.routes.ts    # 社区
│   │   └── sync.routes.ts         # 全量/增量同步
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── user.service.ts
│   │   ├── drink.service.ts
│   │   ├── ai-proxy.service.ts    # DeepSeek SSE 转发
│   │   ├── notification.service.ts # FCM push
│   │   └── sync.service.ts
│   ├── utils/
│   │   ├── jwt.ts
│   │   ├── password.ts            # bcrypt hash
│   │   └── errors.ts              # 自定义错误类
│   └── types/
│       └── index.ts               # 共享类型定义
├── tests/
│   ├── auth.test.ts
│   ├── drink.test.ts
│   └── ai-proxy.test.ts
├── .env.example
├── docker-compose.yml             # PostgreSQL + Redis 本地开发
├── Dockerfile
├── tsconfig.json
├── package.json
└── README.md
```

---

## 4. 数据库 Schema

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(cuid())
  deviceId      String?   @unique   // 设备匿名登录
  phone         String?   @unique
  email         String?   @unique
  passwordHash  String?             // 匿名用户没密码，绑定邮箱后才有
  nickname      String    @default("水友")
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  profile       UserProfile?
  drinkLogs     DrinkLog[]
  memoryFacts   MemoryFact[]
  sessions      SessionSummary[]
  plans         TodayPlan[]
  careContacts  CareContact[]   @relation("owner")
  caredBy       CareContact[]   @relation("contact")
}

model UserProfile {
  id                   String   @id @default(cuid())
  userId               String   @unique
  user                 User     @relation(fields: [userId], references: [id])
  dailyGoalMl          Int      @default(2000)
  wakeTimeHour         Int      @default(7)
  wakeTimeMinute       Int      @default(0)
  bedTimeHour          Int      @default(23)
  bedTimeMinute        Int      @default(0)
  reminderIntervalMin  Int      @default(60)
  reminderStyle        String   @default("gentle")
  notificationsEnabled Boolean  @default(true)
  weightKg             Float?
  activityLevel        String?
  updatedAt            DateTime @updatedAt
}

model DrinkLog {
  id          String    @id @default(cuid())
  userId      String
  user        User      @relation(fields: [userId], references: [id])
  ml          Int
  icon        String    @default("💧")
  description String    @default("喝水")
  loggedAt    DateTime  @default(now())
  syncedAt    DateTime?

  @@index([userId, loggedAt])
}

model MemoryFact {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id])
  category  String
  content   String
  source    String   @default("chat")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId])
}

model SessionSummary {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id])
  summary   String
  createdAt DateTime @default(now())
}

model TodayPlan {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id])
  date      DateTime @db.Date
  planJson  Json
  createdAt DateTime @default(now())

  @@unique([userId, date])
}

model CareContact {
  id        String   @id @default(cuid())
  ownerId   String
  owner     User     @relation("owner", fields: [ownerId], references: [id])
  contactId String
  contact   User     @relation("contact", fields: [contactId], references: [id])
  nickname  String
  createdAt DateTime @default(now())

  @@unique([ownerId, contactId])
}
```

---

## 5. API 设计

### 5.1 Auth（设备匿名登录 + 可选绑定）

采用**零摩擦**认证策略：App 首次启动自动完成匿名登录，用户无感知。需要跨设备同步时，在设置里可选绑定邮箱。

| Method | Path | 鉴权 | 说明 |
|--------|------|------|------|
| POST | `/auth/device` | 无 | 设备匿名登录（deviceId 可选，不传则服务端生成） |
| POST | `/auth/bind-email` | 需要 | 给当前用户绑定邮箱 + 密码（可选） |
| POST | `/auth/login` | 无 | 邮箱 + 密码登录（换设备找回账号） |
| POST | `/auth/refresh` | 无 | 用 refresh token 换新 access token |
| POST | `/auth/logout` | 需要 | 使 refresh token 失效 (Redis 黑名单) |

#### `/auth/device` 详细逻辑

请求体：

```json
{ "deviceId": "550e8400-e29b-41d4-a716-446655440000" }  // 可选
// 或
{}  // 不传也行，服务端自动生成
```

服务端处理：

```
收到 POST /auth/device
  │
  ├── body 有 deviceId 且格式为 UUID？
  │     ├── 数据库找到该 deviceId 的用户 → 签发双 token，返回
  │     └── 数据库找不到 → 创建新匿名用户，返回
  │
  ├── body 有 deviceId 但格式不合法？
  │     └── 返回 400: "deviceId 格式无效，需要 UUID v4"
  │
  └── body 无 deviceId 或为空？
        └── 服务端生成 UUID → 创建新匿名用户，返回
```

响应（始终包含 deviceId，客户端收到后存本地）：

```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "deviceId": "550e8400-e29b-41d4-a716-446655440000",
  "isNewUser": true
}
```

#### `/auth/bind-email` 详细逻辑

```
收到 POST /auth/bind-email { email, password }
  │
  ├── 当前用户已绑定该邮箱？→ 返回 200，幂等
  ├── 邮箱已被其他用户占用？→ 返回 409: "该邮箱已被绑定"
  ├── 密码长度 < 8？→ 返回 400: 校验失败
  └── 正常 → bcrypt hash 密码，更新 User，返回 200
```

#### `/auth/login` 详细逻辑

```
收到 POST /auth/login { email, password }
  │
  ├── 邮箱不存在？→ 返回 401: "邮箱或密码错误"（不泄露具体原因）
  ├── 用户未设密码（纯匿名用户，没绑定过邮箱）？→ 返回 401
  ├── 密码不匹配？→ 返回 401: "邮箱或密码错误"
  └── 正常 → 签发双 token，返回
```

#### `/auth/refresh` 详细逻辑

```
收到 POST /auth/refresh { refreshToken }
  │
  ├── token 格式无效或已过期？→ 返回 401: "Refresh token 无效"
  ├── token 在 Redis 黑名单中？→ 返回 401: "Token 已失效"
  ├── token 对应的用户不存在（已删除）？→ 返回 401
  └── 正常 → 签发新 access token，返回
      （refresh token 本身不轮换，7 天有效期内复用）
```

#### 边界情况与防护

| 场景 | 处理 |
|------|------|
| 同一 deviceId 并发调用 `/auth/device` | Prisma `upsert` 保证幂等，不会创建重复用户 |
| 客户端重装 App，本地 deviceId 丢失 | 新调用不带 deviceId → 创建新匿名用户（如果之前绑了邮箱，可用 `/auth/login` 找回） |
| 用户在 A 设备绑定邮箱，在 B 设备邮箱登录 | B 设备获得同一个 userId 的 token，数据自动打通 |
| access token 过期，refresh token 也过期 | 客户端用本地 deviceId 重新调 `/auth/device`，拿回同一用户 |
| 恶意刷 `/auth/device` 批量创建用户 | auth 接口限流 5 次/分钟/IP（已在 rate-limit.ts 配置） |
| refresh token 泄露 | `/auth/logout` 加入 Redis 黑名单；access token 15 分钟短过期限制窗口 |
| 用户想换绑邮箱 | 当前版本不支持换绑，后续可加 `/auth/unbind-email`（需验证旧密码） |
| 服务端宕机重启，Redis 清空 | refresh token 黑名单丢失，已登出的 token 可能被复用——可接受（15 分钟窗口） |

#### 认证流程图

```
Flutter App 启动
    │
    ├── SharedPreferences 有 access_token？
    │     ├── 未过期 → 直接用，正常请求 API
    │     └── 已过期 → POST /auth/refresh
    │           ├── 成功 → 存新 access_token，继续
    │           └── 失败 → 走下面 ↓
    │
    └── 没有 token 或 refresh 失败？
          ├── 本地有 device_id → POST /auth/device { deviceId }
          └── 本地无 device_id → POST /auth/device {}
                ↓
          收到响应 → 存 access_token + refresh_token + device_id
                ↓
          正常使用 App（用户全程无感知）

换设备场景：
    新设备 → 没有 device_id → 创建新匿名用户
    设置页 → "我有账号" → 输入邮箱密码 → POST /auth/login
    → 获得老账号的 token → 本地数据被云端数据覆盖
```

### 5.2 AI Proxy

| Method | Path | 说明 |
|--------|------|------|
| POST | `/ai/chat` | SSE streaming proxy → DeepSeek |
| POST | `/ai/plan` | 生成每日计划 |

SSE Proxy 关键逻辑：
- 客户端发 messages + tools → 后端注入 API Key → 转发到 DeepSeek → SSE 流回客户端
- 后端可注入/修改 system prompt（加入服务端持有的用户数据）
- 记录 token 消耗做计费/限流
- 过滤敏感内容

### 5.3 Drink Logs

| Method | Path | 说明 |
|--------|------|------|
| POST | `/drinks` | 记录喝水 |
| GET | `/drinks/today` | 今日汇总 + 日志列表 |
| GET | `/drinks/history?from=&to=` | 历史数据 |
| GET | `/drinks/streak` | 连续达标天数 |

### 5.4 User

| Method | Path | 说明 |
|--------|------|------|
| GET | `/user/profile` | 获取档案 |
| PUT | `/user/profile` | 更新档案 |

### 5.5 Sync

| Method | Path | 说明 |
|--------|------|------|
| POST | `/sync/push` | 客户端推送本地变更 |
| GET | `/sync/pull?since=` | 拉取增量变更 |

---

## 6. 注意事项

### 6.1 AI Proxy — SSE 流式转发

```typescript
app.post('/ai/chat', auth, rateLimit, async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  const upstream = await fetch('https://api.deepseek.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ ...req.body, stream: true }),
  });

  // 直接 pipe SSE 流到客户端
  upstream.body.pipe(res);
});
```

注意点：
- 禁用 compression 对 SSE 路由
- 设置合理 timeout（DeepSeek 长回复 30-60s）
- 客户端断连时 abort upstream 请求（避免浪费 token）

### 6.2 离线优先同步策略

```
Local-first + 后台同步：
1. 所有操作先写本地 (SharedPreferences / Hive)
2. 有网时后台推送到服务端
3. 拉取时用 last_synced_at 做增量同步
4. 冲突解决：last-write-wins（对饮水日志足够）
```

### 6.3 Rate Limiting

AI 接口必须严格限流：
- 每用户每分钟最多 10 次 chat 请求
- 用 Redis 存储计数
- 超限返回 429 + 友好提示

### 6.4 安全清单

- [ ] DeepSeek API Key 只存服务端环境变量，永不返回客户端
- [ ] JWT secret 用 256-bit 随机值
- [ ] 密码用 bcrypt (cost factor 12+)（仅绑定邮箱时）
- [ ] 所有输入用 Zod 校验
- [ ] 启用 helmet (安全 headers) + cors (限定 origin)
- [ ] AI 请求前过滤 prompt injection
- [ ] 敏感字段（手机号、邮箱）脱敏返回
- [ ] deviceId 校验格式（UUID v4），防止伪造

### 6.5 Flutter 客户端改造

后端就绪后，Flutter 端需要：

1. **`AiService`**: baseUrl 从 `https://api.deepseek.com` 改为后端地址，Authorization 改为 JWT
2. **`AiConfig`**: 不再存储 API Key，改为存 JWT token
3. **新增 `AuthService`**: 启动时调用 `ensureAuthenticated()` 静默完成设备登录，无需任何 UI
4. **`UserProvider`**: 增加同步逻辑（本地写入 → 队列 → 后台推送）
5. **`DrinkLog`**: 增加 `syncedAt` 字段标记同步状态
6. **设置页**: 增加"绑定邮箱"入口（可选），用于跨设备找回数据

Flutter 端认证伪代码：

```dart
class AuthService {
  /// App 启动时调用，用户全程无感知
  Future<void> ensureAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 已有 access token → 尝试直接用
    final accessToken = prefs.getString('access_token');
    if (accessToken != null && !_isExpired(accessToken)) return;

    // 2. access token 过期 → 尝试 refresh
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken != null) {
      try {
        final res = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
        await prefs.setString('access_token', res.data['accessToken']);
        return;
      } catch (_) {
        // refresh 也失败，继续走设备登录
      }
    }

    // 3. 没有 token 或全部失效 → 设备匿名登录
    final deviceId = prefs.getString('device_id'); // 可能有也可能没有
    final res = await dio.post('/auth/device', data: {
      if (deviceId != null) 'deviceId': deviceId,
    });
    await prefs.setString('access_token', res.data['accessToken']);
    await prefs.setString('refresh_token', res.data['refreshToken']);
    await prefs.setString('device_id', res.data['deviceId']); // 始终以服务端返回值为准
  }
}
```

---

## 7. 开发阶段

### Phase 1 — 基础骨架 ✅ 已完成

- [x] Express + TypeScript 项目初始化
- [x] docker-compose (PostgreSQL + Redis，本地用 Podman)
- [x] Prisma schema + 初始 migration
- [x] 全局 middleware (error handler, logger, cors, helmet)
- [x] 健康检查 `GET /health`
- [x] 工具类 (jwt, password, errors)
- [x] 配置层 (env, prisma, redis, logger)

### Phase 2 — Auth ✅ 已完成

- [x] `POST /auth/device` — 设备匿名登录（首次自动创建用户）
- [x] `POST /auth/bind-email` — 可选绑定邮箱 + 密码
- [x] `POST /auth/login` — 邮箱密码登录（换设备找回）
- [x] `POST /auth/refresh` — Token 刷新
- [x] `POST /auth/logout` — 登出（Redis 黑名单）
- [x] Prisma migration: User 表加 `deviceId`，`passwordHash` 改可选
- [ ] 测试

### Phase 3 — AI Proxy ✅ 已完成

- [x] SSE streaming proxy
- [x] Rate limiting
- [ ] Token 计数（可选）
- [x] Flutter 端 AiService 对接

### Phase 4 — 数据 CRUD ✅ 已完成

- [x] DrinkLog CRUD + 批量同步 (bulk-sync)
- [x] UserProfile CRUD
- [x] MemoryFact CRUD
- [x] TodayPlan CRUD
- [x] SessionSummary CRUD
- [x] CareContact CRUD
- [ ] 测试

### Phase 5 — 同步 (2-3 天)

- [ ] Push / Pull 接口
- [ ] 冲突解决
- [ ] Flutter 端同步队列
- [ ] 离线/在线切换

### Phase 6 — 社区 (后续)

- [ ] 真实 CareContact 关系
- [ ] 排行榜
- [ ] 推送通知 (FCM)

---

## 8. 依赖

```json
{
  "dependencies": {
    "express": "^4.21",
    "@prisma/client": "^6",
    "zod": "^3",
    "jsonwebtoken": "^9",
    "bcryptjs": "^3",
    "cors": "^2",
    "helmet": "^8",
    "pino": "^9",
    "pino-http": "^10",
    "ioredis": "^5",
    "rate-limiter-flexible": "^5",
    "dotenv": "^16"
  },
  "devDependencies": {
    "typescript": "^5.7",
    "tsx": "^4",
    "prisma": "^6",
    "vitest": "^3",
    "supertest": "^7",
    "@types/express": "^5",
    "@types/jsonwebtoken": "^9",
    "@types/bcryptjs": "^3",
    "@types/cors": "^2",
    "@types/supertest": "^6"
  }
}
```

---

## 9. 架构总览

```
Flutter App (local-first)
    │
    ├── 本地操作照常走 SharedPreferences / Hive
    │
    └── 网络层 ──→ Express.js Backend
                     ├── /auth/*       → PostgreSQL (用户系统)
                     ├── /ai/chat      → DeepSeek API (SSE proxy, key 安全)
                     ├── /drinks/*     → PostgreSQL (云端备份)
                     ├── /sync/*       → PostgreSQL (增量同步)
                     └── /community/*  → PostgreSQL (真实社交)
```

核心原则：**客户端体验不降级**（断网照常用），**API Key 安全**（不再暴露），**数据不丢失**（云端备份）。
