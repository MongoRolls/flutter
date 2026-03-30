# KeLeME Backend

KeLeME (渴了么) AI 饮水提醒 App 后端服务。基于 **Node.js 20 + Express 4 + TypeScript + Prisma + PostgreSQL + Redis** 构建。

> **容器运行时**：本项目统一使用 **Podman**（而非 Docker）管理容器和镜像。以下所有命令均基于 `podman` / `podman-compose`。

---

## 目录

- [环境要求](#环境要求)
- [快速启动](#快速启动)
- [环境变量配置](#环境变量配置)
- [数据库管理](#数据库管理)
- [可用脚本](#可用脚本)
- [项目结构](#项目结构)
- [API 概览](#api-概览)
- [部署](#部署)
  - [PM2 部署（推荐）](#pm2-部署推荐)
  - [容器部署](#容器部署)
  - [生产环境完整流程](#生产环境完整流程)
- [监控与运维](#监控与运维)
- [常见问题](#常见问题)
- [开发进度](#开发进度)

---

## 环境要求

| 依赖       | 最低版本 | 说明                         |
| ---------- | -------- | ---------------------------- |
| Node.js    | 20 LTS   | 推荐使用 `nvm` 管理版本     |
| npm        | 9+       | 随 Node.js 附带             |
| Podman     | 4+       | 用于运行 PostgreSQL 和 Redis |
| podman-compose | 1.0+ | Compose 文件编排             |
| PostgreSQL | 16       | 通过 Podman 容器运行         |
| Redis      | 7        | 通过 Podman 容器运行         |
| PM2        | 5+       | 生产部署进程管理（可选）     |

---

## 快速启动

### 1. 启动基础设施 (PostgreSQL + Redis)

```bash
cd backend
podman-compose up -d
```

这会启动：

- **PostgreSQL 16** - `localhost:5432`，用户 `keleme`，数据库 `keleme_db`
- **Redis 7** - `localhost:6379`

验证服务是否就绪：

```bash
podman-compose ps
# 确认两个容器状态为 running (healthy)
```

### 2. 安装依赖

```bash
npm install
```

### 3. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env，填入实际的 JWT 密钥和 DeepSeek API Key
```

生成 JWT 密钥：

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
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
KeLeME 后端服务已启动，端口 3000，环境 development
```

### 6. 验证服务

```bash
curl http://localhost:3000/health
# {"status":"ok","timestamp":"...","service":"keleme-backend","checks":{"postgres":"ok","redis":"ok"}}
```

---

## 环境变量配置

所有环境变量在启动时通过 Zod 进行严格校验，缺少或格式错误会导致进程立即退出。

模板文件：`.env.example`

```bash
# ── 服务器配置 ─────────────────────────────────────────
NODE_ENV=development          # development | production | test
PORT=3000                     # 监听端口，默认 3000

# ── 数据库 ─────────────────────────────────────────────
DATABASE_URL="postgresql://keleme:keleme_dev_password@localhost:5432/keleme_db"

# ── Redis ──────────────────────────────────────────────
REDIS_URL="redis://localhost:6379"

# ── JWT 密钥 ───────────────────────────────────────────
# 最少 32 字符。生产环境请使用强随机值
JWT_SECRET="<your-256-bit-hex>"
JWT_REFRESH_SECRET="<your-256-bit-hex>"

# ── DeepSeek AI ────────────────────────────────────────
# 必须以 sk- 开头
DEEPSEEK_API_KEY="sk-your-api-key"

# ── CORS ───────────────────────────────────────────────
# 允许的前端来源，默认 *。生产环境填写具体域名
CORS_ORIGIN="*"
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
| `npm run deploy:prod` | 生产更新（`npm ci`、迁移、构建、`pm2 reload`） |
| `npm run deploy:prod:pull` | 同上且先执行 `git pull` |
| `npm run deploy:podman` | Podman Compose 全栈：`up -d` + `prisma migrate deploy` |
| `npm run deploy:podman:pull` | 同上且先 `podman-compose pull`（用 ghcr 镜像发版） |

---

## 项目结构

```
backend/
├── scripts/
│   ├── deploy.sh                  # 生产更新（PM2 路径）；见[部署](#部署)
│   └── deploy-podman.sh           # 生产更新（Podman Compose 全栈）
├── prisma/
│   ├── schema.prisma              # 数据模型定义（7 个模型）
│   └── migrations/                # 数据库迁移文件
├── src/
│   ├── index.ts                   # 入口：启动服务器，优雅关闭（SIGTERM/SIGINT）
│   ├── app.ts                     # Express 实例，中间件 + 9 组路由挂载
│   ├── config/
│   │   ├── env.ts                 # Zod 环境变量校验
│   │   ├── prisma.ts              # PrismaClient 单例
│   │   ├── redis.ts               # ioredis 实例（启动时验证连接）
│   │   └── logger.ts              # Pino 日志（开发环境 pino-pretty）
│   ├── middleware/
│   │   ├── auth.ts                # JWT Bearer Token 验证
│   │   ├── rate-limit.ts          # Redis 令牌桶限流（3 档）
│   │   ├── validate.ts            # Zod Schema 请求校验
│   │   └── error-handler.ts       # 全局错误处理 -> JSON 响应
│   ├── routes/
│   │   ├── health.routes.ts       # GET /health（深度检查 PG + Redis）
│   │   ├── auth.routes.ts         # /auth/* (5 个端点)
│   │   ├── profile.routes.ts      # /api/profile
│   │   ├── drink-logs.routes.ts   # /api/drink-logs (含批量同步)
│   │   ├── plans.routes.ts        # /api/plans
│   │   ├── memory.routes.ts       # /api/memory
│   │   ├── sessions.routes.ts     # /api/sessions
│   │   ├── ai.routes.ts           # /api/ai/chat (SSE 流式代理)
│   │   └── care.routes.ts         # /api/care/contacts
│   ├── services/
│   │   ├── auth.service.ts        # 认证业务逻辑
│   │   ├── profile.service.ts     # 用户配置
│   │   ├── drink-log.service.ts   # 饮水记录（含聚合、去重）
│   │   ├── plan.service.ts        # 每日计划
│   │   ├── memory.service.ts      # AI 记忆（含分页）
│   │   ├── session.service.ts     # 会话摘要
│   │   └── care.service.ts        # 社交关怀联系人
│   ├── utils/
│   │   ├── jwt.ts                 # JWT 签发 / 验证（access 15min, refresh 7d）
│   │   ├── password.ts            # bcrypt 哈希 / 校验（cost 12）
│   │   └── errors.ts              # AppError 错误体系（6 种错误类）
│   └── types/
│       └── index.ts               # AuthenticatedRequest 类型定义
├── ecosystem.config.cjs           # PM2 进程管理配置
├── docker-compose.yml             # 开发环境 PostgreSQL + Redis（podman-compose 兼容）
├── docker-compose.prod.yml        # 生产全栈（镜像变量 KELEME_BACKEND_IMAGE）
├── docker-compose.prod.local.yml  # 与上一文件合并：本地从 Dockerfile 构建 API
├── Dockerfile                     # 生产多阶段构建（podman build 兼容）
├── .env.example                   # 环境变量模板
├── package.json
└── tsconfig.json
```

> **仓库级文档**（前后端协作、饮水同步与 Prisma 运维摘要）：仓库根目录 `.cursor/project/README.md`（自 `backend/` 为 `../.cursor/project/README.md`）。**生产部署规范**：`../.cursor/project/后端部署规范.md`。

> **文件命名说明**：`docker-compose.yml` 和 `Dockerfile` 保留原名以兼容 OCI 标准工具链。实际运行时使用 `podman-compose` 和 `podman build`。

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

| 方法 | 路径      | 说明                             | 认证 |
| ---- | --------- | -------------------------------- | ---- |
| GET  | `/health` | 深度检查（PostgreSQL + Redis）   | 无   |

---

## 部署

**仓库级规范（默认架构、更新与 Prisma 流程）**：仓库根目录 `.cursor/project/后端部署规范.md`（自 `backend/` 为 `../.cursor/project/后端部署规范.md`）。生产 VPS 默认 **PM2 + 仅容器跑 PostgreSQL/Redis**（`docker-compose.yml`）。

支持三种部署方式，按推荐程度排列：

1. **PM2 部署** — 适合 VPS / 云主机，简单高效，推荐首选
2. **容器部署** — 适合容器化环境（使用 Podman）
3. **Podman Compose 全栈部署** — 一键拉起所有服务

### PM2 部署（推荐）

PM2 是 Node.js 生产环境进程管理器，提供自动重启、负载均衡、日志管理和监控。

#### 前置准备

```bash
# 全局安装 PM2
npm install -g pm2

# 服务器上启动 PostgreSQL 16 和 Redis 7
podman-compose up -d
```

#### 首次部署

```bash
cd backend

# 1. 安装依赖
npm ci --omit=dev

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env，设置生产配置：
#   NODE_ENV=production
#   DATABASE_URL=<生产数据库连接>
#   JWT_SECRET=<强随机密钥>
#   JWT_REFRESH_SECRET=<强随机密钥>
#   DEEPSEEK_API_KEY=<API 密钥>
#   CORS_ORIGIN=https://your-domain.com

# 3. 生成 Prisma Client 并执行迁移
npx prisma generate
npx prisma migrate deploy

# 4. 编译 TypeScript
npm run build

# 5. 启动 PM2
pm2 start ecosystem.config.cjs --env production

# 6. 保存进程列表（服务器重启后自动恢复）
pm2 save

# 7. 设置开机自启
pm2 startup
# 按照输出的命令执行（通常需要 sudo）
```

#### 更新部署

**推荐**：使用脚本一键部署（含依赖、迁移、构建、PM2 reload）。

```bash
cd backend
./scripts/deploy.sh --with-git-pull   # 含 git pull（VPS 上常用）
# 或已在该目录手动 git pull 后，只构建与 reload：
./scripts/deploy.sh
```

等价：`npm run deploy:prod:pull` / `npm run deploy:prod`。

**等价手写**：

```bash
cd backend

# 拉取最新代码
git pull origin main

# 安装依赖（如有变化）
npm ci --omit=dev

# 执行数据库迁移（如有变化）
npx prisma generate
npx prisma migrate deploy

# 重新编译
npm run build

# 零停机重载（cluster 模式下逐个重启实例）
pm2 reload ecosystem.config.cjs --env production
```

#### PM2 常用命令

```bash
# ── 进程管理 ─────────────────────────────────────────────
pm2 list                          # 查看所有进程状态
pm2 show keleme-api               # 查看详细信息
pm2 restart keleme-api            # 重启（有短暂停机）
pm2 reload keleme-api             # 零停机重载（推荐）
pm2 stop keleme-api               # 停止
pm2 delete keleme-api             # 删除进程

# ── 日志 ─────────────────────────────────────────────────
pm2 logs keleme-api               # 实时查看日志
pm2 logs keleme-api --lines 100   # 查看最近 100 行
pm2 flush                         # 清空所有日志

# ── 监控 ─────────────────────────────────────────────────
pm2 monit                         # 终端实时监控面板
pm2 plus                          # PM2 Plus 在线监控（可选）

# ── 集群管理 ─────────────────────────────────────────────
pm2 scale keleme-api 4            # 扩展到 4 个实例
pm2 scale keleme-api +2           # 增加 2 个实例
```

#### PM2 配置说明

配置文件 `ecosystem.config.cjs` 关键参数：

| 参数               | 值         | 说明                               |
| ------------------ | ---------- | ---------------------------------- |
| `instances`        | `'max'`    | 按 CPU 核心数自动扩展             |
| `exec_mode`        | `'cluster'`| 多进程负载均衡                     |
| `max_memory_restart` | `'512M'` | 内存超限自动重启                   |
| `restart_delay`    | `5000`     | 重启间隔 5 秒，避免频繁重启       |
| `max_restarts`     | `10`       | 最大连续重启次数                   |
| `kill_timeout`     | `10000`    | 优雅关闭超时（与 index.ts 一致）   |
| `merge_logs`       | `true`     | 多实例日志合并到同一文件           |

> **SSE 注意**：AI 聊天接口使用 SSE 流式传输。如果在 cluster 模式下遇到 SSE 连接问题，可以在 `ecosystem.config.cjs` 中将 `exec_mode` 改为 `'fork'`，`instances` 改为 `1`。

#### PM2 + Nginx 反向代理

生产环境推荐在 PM2 前面加 Nginx 做反向代理：

```nginx
upstream keleme_api {
    # PM2 cluster 模式只监听一个端口，Nginx 直接转发即可
    server 127.0.0.1:3000;
    keepalive 64;
}

server {
    listen 80;
    server_name api.keleme.example.com;

    # 强制 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.keleme.example.com;

    ssl_certificate     /etc/ssl/certs/keleme.pem;
    ssl_certificate_key /etc/ssl/private/keleme.key;

    # 安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;

    location / {
        proxy_pass http://keleme_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # SSE 流式接口 — 禁用缓冲
    location /api/ai/chat {
        proxy_pass http://keleme_api;
        proxy_http_version 1.1;
        proxy_set_header Connection '';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding off;
        proxy_read_timeout 300s;   # SSE 长连接超时
    }
}
```

### 容器部署

#### 构建镜像

```bash
cd backend

# 构建镜像
podman build -t keleme-backend .

# 运行容器
podman run -d \
  --name keleme-api \
  -p 3000:3000 \
  --env-file .env \
  --restart unless-stopped \
  keleme-backend
```

Dockerfile 采用多阶段构建（与 Podman 完全兼容）：

1. **builder 阶段** - 安装所有依赖，生成 Prisma Client，编译 TypeScript
2. **runner 阶段** - 仅安装生产依赖，复制编译产物，暴露端口 3000

内置健康检查：每 30 秒请求 `GET /health`。

#### Podman Compose 开发环境

```bash
# 启动 PostgreSQL + Redis
podman-compose up -d

# 查看日志
podman-compose logs -f

# 停止服务
podman-compose down

# 停止并清除数据卷
podman-compose down -v
```

#### Podman Compose 生产全栈部署

**VPS 推荐（免整仓 `git clone`）**：将 API 镜像推送到 **ghcr.io**（本地 `podman build` / `podman push` 或自建 CI），服务器只保留 `backend/docker-compose.prod.yml`、`.env` 与 `scripts/deploy-podman.sh`（可用 `scp` 同步），在 `.env` 中设置：

- `KELEME_BACKEND_IMAGE=ghcr.io/<owner>/<repo>/keleme-backend:latest`
- `POSTGRES_PASSWORD`（与 compose 内一致）

私有镜像需先登录：`podman login ghcr.io`（用户名 GitHub，密码为 PAT 或 `GITHUB_TOKEN` 只读权限）。

```bash
cd backend
cp .env.example .env
# 编辑 .env：JWT、DeepSeek、CORS、KELEME_BACKEND_IMAGE、POSTGRES_PASSWORD 等

# 一键：pull（可选）+ up + migrate deploy
./scripts/deploy-podman.sh --pull
# 或已是最新镜像：./scripts/deploy-podman.sh

# 查看日志 / 状态
podman-compose -f docker-compose.prod.yml logs -f api
podman-compose -f docker-compose.prod.yml ps
```

**本地从源码构建 API 镜像**（不依赖 registry）：

```bash
cd backend
podman-compose -f docker-compose.prod.yml -f docker-compose.prod.local.yml up -d --build
# 默认 KELEME_BACKEND_IMAGE 未设置时使用标签 keleme-backend:local（由 build 产生）
podman-compose -f docker-compose.prod.yml exec api npx prisma migrate deploy
```

### 生产环境完整流程

无论使用哪种部署方式，生产环境都需要完成以下步骤：

```bash
# 1. 准备环境变量
cp .env.example .env
# 编辑 .env，设置：
#   NODE_ENV=production
#   DATABASE_URL=<生产数据库连接字符串>
#   REDIS_URL=<生产 Redis 连接字符串>
#   JWT_SECRET=<node -e "console.log(require('crypto').randomBytes(32).toString('hex'))">
#   JWT_REFRESH_SECRET=<同上，再生成一个>
#   DEEPSEEK_API_KEY=<sk-your-key>
#   CORS_ORIGIN=https://your-domain.com

# 2. 数据库迁移（生产环境用 deploy 而非 dev）
npx prisma migrate deploy

# 3. 启动服务（选其一）
pm2 start ecosystem.config.cjs --env production              # PM2
# 或（全栈容器，含迁移）
./scripts/deploy-podman.sh --pull                            # Podman Compose + ghcr 镜像
```

> **注意**：生产环境使用 `prisma migrate deploy` 而非 `prisma migrate dev`，前者只执行已有迁移，不会创建新迁移。

### 部署方式对比

| 特性             | PM2              | Podman           | Podman Compose 全栈 |
| ---------------- | ---------------- | ---------------- | -------------------- |
| 适用场景         | VPS / 云主机     | 容器化平台       | 快速搭建完整环境     |
| 零停机更新       | `pm2 reload`     | 需配合编排工具   | `podman-compose up -d` |
| 多实例负载均衡   | cluster 模式     | 需外部 LB        | 需外部 LB            |
| 日志管理         | 内置             | `podman logs`    | `podman-compose logs` |
| 监控             | `pm2 monit` / Plus | 需额外工具      | 需额外工具           |
| 开机自启         | `pm2 startup`    | `--restart`      | `restart: unless-stopped` |
| 学习成本         | 低               | 中               | 中                   |
| 无守护进程       | 否               | 是（rootless）   | 是（rootless）       |

---

## 监控与运维

### 健康检查

```bash
# HTTP 健康检查（深度检查 PostgreSQL + Redis）
curl http://localhost:3000/health

# Podman 容器健康检查（Dockerfile 已配置）
podman inspect --format='{{.State.Health.Status}}' keleme-api

# PM2 进程状态
pm2 show keleme-api
```

### 日志查看

```bash
# PM2 日志
pm2 logs keleme-api               # 实时
pm2 logs keleme-api --lines 200   # 最近 200 行

# Podman 日志
podman logs -f keleme-api         # 实时
podman logs --tail 200 keleme-api # 最近 200 行

# 日志文件位置（PM2）
# logs/out.log    — 标准输出
# logs/error.log  — 错误日志
```

### 数据库备份

```bash
# 导出数据库
pg_dump -U keleme -d keleme_db > backup_$(date +%Y%m%d).sql

# Podman 环境导出
podman exec keleme_postgres pg_dump -U keleme -d keleme_db > backup_$(date +%Y%m%d).sql

# 恢复数据库
psql -U keleme -d keleme_db < backup_20260326.sql
```

---

## 常见问题

### 启动报错 "环境变量校验失败"

确认 `.env` 文件存在且所有必填变量格式正确。特别注意：

- `DATABASE_URL` 和 `REDIS_URL` 必须是合法 URL
- `JWT_SECRET` 和 `JWT_REFRESH_SECRET` 至少 32 字符
- `DEEPSEEK_API_KEY` 必须以 `sk-` 开头

### 连不上数据库

```bash
# 检查 Podman 容器状态
podman-compose ps

# 如果容器未启动
podman-compose up -d

# 检查 PostgreSQL 是否就绪
podman exec keleme_postgres pg_isready -U keleme -d keleme_db
```

### 端口被占用

```bash
# 查找占用 3000 端口的进程
lsof -i :3000

# 或修改 .env 中的 PORT 值
```

### PM2 进程启动失败

```bash
# 查看错误日志
pm2 logs keleme-api --err --lines 50

# 常见原因：
# 1. dist/ 目录不存在 → 先运行 npm run build
# 2. .env 配置错误 → 检查环境变量
# 3. 数据库未迁移 → 运行 npx prisma migrate deploy
# 4. 端口被占用 → 检查 lsof -i :3000

# 强制重启
pm2 delete keleme-api
pm2 start ecosystem.config.cjs --env production
```

### PM2 cluster 模式下 SSE 异常

如果 AI 聊天接口的 SSE 流式响应在 cluster 模式下不稳定：

```bash
# 方案 1：改为 fork 模式
# 编辑 ecosystem.config.cjs:
#   exec_mode: 'fork'
#   instances: 1

# 方案 2：使用 Nginx sticky session
# 在 upstream 配置中添加 ip_hash
```

### Podman Machine 未启动（macOS）

```bash
# 检查 Podman Machine 状态
podman machine list

# 如果未运行
podman machine start

# 验证
podman info
```

### 重置开发环境

```bash
# 清除数据库数据并重新迁移
npm run db:reset

# 彻底重置（包括 Podman 数据卷）
podman-compose down -v
podman-compose up -d
npm run db:migrate
```

---

## 开发进度

| 阶段 | 内容 | 状态 |
| ---- | ---- | ---- |
| Phase 1 | 基础骨架（Express + Prisma + 中间件 + 健康检查） | ✅ 已完成 |
| Phase 2 | Auth（设备登录 + 邮箱绑定 + JWT + 登出） | ✅ 已完成 |
| Phase 3 | AI Proxy（SSE 流式代理 + 限流） | ✅ 已完成 |
| Phase 4 | 数据 CRUD（DrinkLog + Profile + Memory + Plan + Session + Care） | ✅ 已完成 |
| Phase 5 | 同步（Push / Pull + 冲突解决 + Flutter 同步队列） | 🔲 待开发 |
| Phase 6 | 社区（真实社交关系 + 排行榜 + FCM 推送） | 🔲 待开发 |

前后端协作与现状摘要见仓库根目录 `.cursor/project/README.md`。
