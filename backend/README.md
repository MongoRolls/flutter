# KeLeME Backend

KeLeME (渴了么) AI 饮水提醒 App 后端服务。基于 **Node.js 20 + Express 4 + TypeScript + Prisma + PostgreSQL + Redis** 构建。

---

## 目录

- [环境要求](#环境要求)
- [快速启动](#快速启动)
- [环境变量配置](#环境变量配置)
- [数据库管理](#数据库管理)
- [可用脚本](#可用脚本)
- [Docker 生产部署](#docker-生产部署)
- [项目结构](#项目结构)
- [API 概览](#api-概览)

---

## 环境要求

| 依赖       | 最低版本 | 说明                         |
| ---------- | -------- | ---------------------------- |
| Node.js    | 20 LTS   | 推荐使用 `nvm` 管理版本     |
| npm        | 9+       | 随 Node.js 附带             |
| Docker｜Podman | 20+  | 用于运行 PostgreSQL 和 Redis |
| PostgreSQL | 16       | 通过 Docker 或系统安装       |
| Redis      | 7        | 通过 Docker 或系统安装       |

---

## 快速启动

### 1. 启动基础设施 (PostgreSQL + Redis)

```bash
cd backend
docker-compose up -d
```

这会启动：

- **PostgreSQL 16** - `localhost:5432`，用户 `keleme`，数据库 `keleme_db`
- **Redis 7** - `localhost:6379`

验证服务是否就绪：

```bash
docker-compose ps
# 确认两个容器状态为 running (healthy)
```

### 2. 安装依赖

```bash
npm install
```

### 3. 配置环境变量

复制 `.env` 模板并按需修改（详见 [环境变量配置](#环境变量配置)）：

```bash
cp .env.example .env   # 如果有 .env.example
# 或直接编辑 .env
```

### 4. 初始化数据库

```bash
# 生成 Prisma Client
npm run db:generate

# 执行数据库迁移
npm run db:migrate
```

### 5. 启动开发服务器

```bash
npm run dev
```

服务启动后输出：

```
🚀 KeLeME 后端服务已启动，端口 3000，环境 development
```

### 6. 验证服务

```bash
curl http://localhost:3000/health
```

---

## 环境变量配置

所有环境变量在启动时通过 Zod 进行严格校验，缺少或格式错误会导致进程立即退出。

在 `backend/.env` 中配置：

```bash
# ── 服务器配置 ─────────────────────────────────────────
NODE_ENV=development          # development | production | test
PORT=3000                     # 监听端口，默认 3000

# ── 数据库 ─────────────────────────────────────────────
DATABASE_URL="postgresql://keleme:keleme_dev_password@localhost:5432/keleme_db"

# ── Redis ──────────────────────────────────────────────
REDIS_URL="redis://localhost:6379"

# ── JWT 密钥 ───────────────────────────────────────────
# 最少 32 字符。生产环境请使用强随机值：
#   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
JWT_SECRET="<your-256-bit-hex>"
JWT_REFRESH_SECRET="<your-256-bit-hex>"

# ── DeepSeek AI ────────────────────────────────────────
# 必须以 sk- 开头
DEEPSEEK_API_KEY="sk-your-api-key"

# ── CORS ───────────────────────────────────────────────
# 允许的前端来源，默认 *。生产环境填写具体域名
CORS_ORIGIN="http://localhost:3000"
```

### 变量校验规则

| 变量               | 类型   | 必填 | 校验规则                                  |
| ------------------ | ------ | ---- | ----------------------------------------- |
| `NODE_ENV`         | string | 否   | `development` / `production` / `test`     |
| `PORT`             | number | 否   | 数字，默认 `3000`                         |
| `DATABASE_URL`     | string | 是   | 合法 URL 格式                             |
| `REDIS_URL`        | string | 是   | 合法 URL 格式                             |
| `JWT_SECRET`       | string | 是   | 最少 32 字符                              |
| `JWT_REFRESH_SECRET` | string | 是 | 最少 32 字符                              |
| `DEEPSEEK_API_KEY` | string | 是   | 必须以 `sk-` 开头                         |
| `CORS_ORIGIN`      | string | 否   | 默认 `*`                                  |

---

## 数据库管理

后端使用 **Prisma ORM** 管理 PostgreSQL，Schema 定义在 `prisma/schema.prisma`。

```bash
# 执行迁移（开发环境，会自动生成 Prisma Client）
npm run db:migrate

# 仅重新生成 Prisma Client（不迁移）
npm run db:generate

# 打开 Prisma Studio 可视化管理数据库
npm run db:studio

# 重置数据库（删除所有数据并重新执行迁移）
npm run db:reset
```

### 数据模型

| 模型             | 说明                                     |
| ---------------- | ---------------------------------------- |
| `User`           | 用户，支持设备匿名登录 + 可选邮箱绑定   |
| `UserProfile`    | 用户配置（目标水量、提醒时间、体重等）   |
| `DrinkLog`       | 饮水记录，含同步时间戳                   |
| `MemoryFact`     | AI 长期记忆存储                          |
| `SessionSummary` | AI 对话摘要                              |
| `TodayPlan`      | 每日饮水计划（JSON），按用户+日期唯一    |
| `CareContact`    | 社交关怀联系人                           |

---

## 可用脚本

所有命令在 `backend/` 目录下执行：

| 命令               | 说明                                        |
| ------------------ | ------------------------------------------- |
| `npm run dev`      | 开发模式，`tsx watch` 热重载                |
| `npm run build`    | TypeScript 编译到 `dist/`                   |
| `npm start`        | 生产模式运行 `node dist/index.js`           |
| `npm test`         | Vitest 监听模式运行测试                     |
| `npm run test:run` | Vitest 单次运行测试                         |
| `npm run db:migrate`  | 执行 Prisma 数据库迁移                   |
| `npm run db:generate` | 重新生成 Prisma Client                   |
| `npm run db:studio`   | 启动 Prisma Studio (可视化数据库管理)     |
| `npm run db:reset`    | 重置数据库                               |

---

## Docker 生产部署

### 使用 Dockerfile 构建镜像

```bash
cd backend

# 构建镜像
docker build -t keleme-backend .

# 运行容器
docker run -d \
  --name keleme-api \
  -p 3000:3000 \
  --env-file .env \
  keleme-backend
```

Dockerfile 采用多阶段构建：

1. **builder 阶段** - 安装所有依赖，生成 Prisma Client，编译 TypeScript
2. **runner 阶段** - 仅安装生产依赖，复制编译产物，暴露端口 3000

内置健康检查：每 30 秒请求 `GET /health`。

### 使用 docker-compose 一键部署（开发）

```bash
# 启动 PostgreSQL + Redis
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 停止并清除数据卷
docker-compose down -v
```

### 生产部署完整流程

```bash
# 1. 准备 .env 文件（使用生产配置）
cp .env .env.production
# 编辑 .env.production，设置：
#   NODE_ENV=production
#   DATABASE_URL=<生产数据库连接>
#   JWT_SECRET=<新的随机密钥>
#   JWT_REFRESH_SECRET=<新的随机密钥>
#   DEEPSEEK_API_KEY=<API 密钥>
#   CORS_ORIGIN=https://your-domain.com

# 2. 构建镜像
docker build -t keleme-backend:latest .

# 3. 运行数据库迁移（在生产数据库上）
npx prisma migrate deploy

# 4. 启动服务
docker run -d \
  --name keleme-api \
  -p 3000:3000 \
  --env-file .env.production \
  --restart unless-stopped \
  keleme-backend:latest
```

> **注意**：生产环境使用 `prisma migrate deploy` 而非 `prisma migrate dev`，前者只执行已有迁移，不会创建新迁移。

---

## 项目结构

```
backend/
├── prisma/
│   ├── schema.prisma              # 数据模型定义
│   └── migrations/                # 数据库迁移文件
├── src/
│   ├── index.ts                   # 入口：启动服务器，优雅关闭
│   ├── app.ts                     # Express 实例，中间件 + 路由挂载
│   ├── config/
│   │   ├── env.ts                 # Zod 环境变量校验
│   │   ├── prisma.ts              # PrismaClient 单例
│   │   ├── redis.ts               # ioredis 实例
│   │   └── logger.ts              # Pino 日志（开发环境 pino-pretty）
│   ├── middleware/
│   │   ├── auth.ts                # JWT Bearer Token 验证
│   │   ├── rate-limit.ts          # Redis 令牌桶限流（3 档）
│   │   ├── validate.ts            # Zod Schema 请求校验
│   │   └── error-handler.ts       # 全局错误处理 -> JSON 响应
│   ├── routes/
│   │   ├── health.routes.ts       # GET /health
│   │   ├── auth.routes.ts         # /auth/*
│   │   ├── profile.routes.ts      # /api/profile
│   │   ├── drink-logs.routes.ts   # /api/drink-logs
│   │   ├── plans.routes.ts        # /api/plans
│   │   ├── memory.routes.ts       # /api/memory
│   │   ├── sessions.routes.ts     # /api/sessions
│   │   ├── ai.routes.ts           # /api/ai/chat (SSE 流式代理)
│   │   └── care.routes.ts         # /api/care/contacts
│   ├── services/
│   │   └── auth.service.ts        # 认证业务逻辑
│   ├── utils/
│   │   ├── jwt.ts                 # JWT 签发 / 验证
│   │   ├── password.ts            # bcrypt 哈希 / 校验
│   │   └── errors.ts              # AppError 错误体系
│   └── types/
│       └── index.ts               # TypeScript 类型定义
├── docker-compose.yml             # 开发环境 PostgreSQL + Redis
├── Dockerfile                     # 生产多阶段构建
├── package.json
├── tsconfig.json
└── .env                           # 环境变量（不要提交到 Git）
```

---

## API 概览

所有 `/api/*` 接口需要 `Authorization: Bearer <token>` 头。

### 认证

| 方法   | 路径             | 说明                       | 限流      |
| ------ | ---------------- | -------------------------- | --------- |
| POST   | `/auth/device`   | 设备匿名登录（自动创建）  | 5 次/分   |
| POST   | `/auth/bind-email` | 绑定邮箱密码             | 需认证    |
| POST   | `/auth/login`    | 邮箱密码登录               | 5 次/分   |
| POST   | `/auth/refresh`  | 刷新 Access Token          | -         |
| POST   | `/auth/logout`   | 登出（Redis 黑名单）       | 需认证    |

### 用户配置

| 方法 | 路径           | 说明         |
| ---- | -------------- | ------------ |
| GET  | `/api/profile` | 获取用户配置 |
| PUT  | `/api/profile` | 更新用户配置 |

### 饮水记录

| 方法   | 路径                       | 说明                       |
| ------ | -------------------------- | -------------------------- |
| GET    | `/api/drink-logs`          | 查询饮水记录（按日期/范围）|
| POST   | `/api/drink-logs`          | 添加单条记录               |
| POST   | `/api/drink-logs/bulk-sync`| 批量同步（最多 500 条）    |
| DELETE | `/api/drink-logs/:id`      | 删除记录                   |

### 每日计划

| 方法 | 路径          | 说明                           |
| ---- | ------------- | ------------------------------ |
| GET  | `/api/plans`  | 获取指定日期计划 `?date=YYYY-MM-DD` |
| POST | `/api/plans`  | 创建/更新计划（按用户+日期 upsert）|

### AI 记忆

| 方法   | 路径              | 说明           |
| ------ | ----------------- | -------------- |
| GET    | `/api/memory`     | 获取所有记忆   |
| POST   | `/api/memory`     | 创建记忆       |
| DELETE | `/api/memory/:id` | 删除记忆       |

### 会话摘要

| 方法 | 路径             | 说明                    |
| ---- | ---------------- | ----------------------- |
| GET  | `/api/sessions`  | 获取最近 50 条摘要      |
| POST | `/api/sessions`  | 创建会话摘要            |

### AI 对话

| 方法 | 路径            | 说明                              | 限流      |
| ---- | --------------- | --------------------------------- | --------- |
| POST | `/api/ai/chat`  | SSE 流式代理到 DeepSeek API       | 10 次/分  |

### 社交关怀

| 方法   | 路径                     | 说明           |
| ------ | ------------------------ | -------------- |
| GET    | `/api/care/contacts`     | 获取联系人列表 |
| POST   | `/api/care/contacts`     | 添加/更新联系人|
| DELETE | `/api/care/contacts/:id` | 删除联系人     |

### 健康检查

| 方法 | 路径      | 说明         | 认证 |
| ---- | --------- | ------------ | ---- |
| GET  | `/health` | 服务状态检查 | 无   |

---

## 常见问题

### 启动报错 "环境变量校验失败"

确认 `.env` 文件存在且所有必填变量格式正确。特别注意：
- `DATABASE_URL` 和 `REDIS_URL` 必须是合法 URL
- `JWT_SECRET` 和 `JWT_REFRESH_SECRET` 至少 32 字符
- `DEEPSEEK_API_KEY` 必须以 `sk-` 开头

### 连不上数据库

```bash
# 检查 Docker 容器状态
docker-compose ps

# 如果容器未启动
docker-compose up -d

# 检查 PostgreSQL 是否就绪
docker exec keleme_postgres pg_isready -U keleme -d keleme_db
```

### 端口被占用

```bash
# 查找占用 3000 端口的进程
lsof -i :3000

# 或修改 .env 中的 PORT 值
```

### 重置开发环境

```bash
# 清除数据库数据并重新迁移
npm run db:reset

# 彻底重置（包括 Docker 数据卷）
docker-compose down -v
docker-compose up -d
npm run db:migrate
```
