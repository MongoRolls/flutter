# VPS 部署计划（后端 + 域名 + 客户端）

**规范（默认架构与迁移流程）**：`.cursor/project/backend_deployment_standard.md`。

面向 **CentOS Stream 9**、约 **2C2G** 香港 VPS；后端为 `backend/`（Node 20 + PM2 + PostgreSQL + Redis）。按顺序执行，前一步正常再进下一步。

**详细命令与 Nginx 片段**：见 `backend/README.md` 部署章节；**逐步命令清单**：`vps_backend_deploy_steps.md`。

---

## Phase 0：准备

| 项 | 说明 |
|----|------|
| VPS | 已可 SSH（`root` 或部署用户），公网 IP 已知 |
| 域名（可选但生产推荐） | 例如 `api.example.com`，DNS **A 记录** 指向 VPS IP |
| 密钥材料 | `JWT_SECRET`、`JWT_REFRESH_SECRET`（各 ≥32 字符随机）、`DEEPSEEK_API_KEY`（`sk-` 开头） |
| 本机 | 仓库可 `git clone` 或 `git pull` |

---

## Phase 1：服务器基础

1. **系统更新**：`dnf update -y`（按需重启）。
2. **时间同步**：确认 `timedatectl` 时区正确（避免 JWT/日志混乱）。
3. **防火墙**：放行 **22**（SSH）、**80/443**（HTTP/HTTPS）；若暂时直连调试 **3000**，仅建议内网或短期，生产用 Nginx。
4. **内存（2G 建议）**：配置 **swap** 1–2G，降低 OOM 风险。
5. **容器运行时**  
   - 安装 **Podman** + **podman-compose**（与 `vps_backend_deploy_steps.md` §1 一致），用 `backend/docker-compose.yml` 起 PG + Redis（命令为 `podman-compose up -d`）。  
   - 不打算用容器装数据库时，可改为 **本机安装** PostgreSQL 16 与 Redis 7（需自行对齐 `DATABASE_URL` / `REDIS_URL`）。

---

## Phase 2：运行时依赖

1. **Node.js 20 LTS**（建议 nvm 或 NodeSource / 发行版模块）。
2. **全局 PM2**：`npm install -g pm2`。
3. **数据库与 Redis**：  
   - 若 **PM2 裸跑 Node**：用 Phase 1 的 compose **仅**启动 `postgres` + `redis`（见 `backend/docker-compose.yml`），或本机服务。  
   - 若 **全栈容器**：使用 `docker-compose.prod.yml` 一次起 API + PG + Redis（注意 2G 内存与 `README` 中的资源上限）。

---

## Phase 3：部署后端（PM2 路径）

在 `backend/` 目录：

1. **代码**：`git clone` / `git pull`。
2. **环境变量**：`cp .env.example .env`，填写：  
   - `NODE_ENV=production`  
   - `DATABASE_URL`、`REDIS_URL`（与容器或本机一致）  
   - `JWT_SECRET`、`JWT_REFRESH_SECRET`  
   - `DEEPSEEK_API_KEY`  
   - `CORS_ORIGIN`：浏览器会调 API 时填**前端页面 origin**（如 `https://www.example.com`）；仅原生 App 可先收紧为具体域名或按 `backend/README` 约定）
3. **依赖与构建**：`npm ci --omit=dev` → `npx prisma generate` → `npx prisma migrate deploy` → `npm run build`。
4. **PM2**：`pm2 start ecosystem.config.cjs --env production` → `pm2 save` → `pm2 startup`（按提示执行 sudo 命令）。
5. **验证**：`curl http://127.0.0.1:3000/health` 返回 `postgres`/`redis` 正常。

**SSE 注意**：若 `/api/ai/chat` 在 cluster 模式下异常，将 `ecosystem.config.cjs` 改为 `fork` + `instances: 1`（见 `backend/README.md`）。

---

## Phase 4：Nginx 反向代理 + HTTPS

1. 安装 **Nginx**。
2. **Let’s Encrypt**（certbot）为 `api.example.com` 申请证书。
3. 配置 **443** → `proxy_pass http://127.0.0.1:3000`；对 **`/api/ai/chat`** 关闭缓冲、拉长 `proxy_read_timeout`（见 `backend/README.md` 示例）。
4. **80** 重定向到 **HTTPS**。
5. 公网验证：`curl https://api.example.com/health`。

---

## Phase 5：客户端（Flutter）

1. 生产构建时传入 **`BACKEND_URL`**，与 HTTPS 根地址一致，**无路径后缀**：  
   `--dart-define=BACKEND_URL=https://api.example.com`
2. 确认手机网络可访问该域名（无自签证书错误）。
3. 可选：在 App 内提供「服务器地址」设置并调用 `BackendApiService.setBaseUrl`（需产品化时再实现）。

---

## Phase 6：官网（`web/`，可选）

1. 若 Next 站点部署在 **另一域名**，浏览器不直接请求 API 时，CORS 可随业务再收紧；若 **浏览器** 调 API，后端 `CORS_ORIGIN` 必须包含该站点 origin。
2. 下载链接等使用 `NEXT_PUBLIC_*`（见 `web/lib/download-urls.ts`）。

---

## Phase 7：上线后检查清单

- [ ] `https://api.example.com/health` 正常  
- [ ] PM2：`pm2 list` 状态 `online`  
- [ ] 数据库备份策略（`pg_dump` 或云快照）  
- [ ] 仅必要端口对公网开放；SSH 密钥与强密码、fail2ban（可选）  
- [ ] Flutter 生产包已带正确 `BACKEND_URL`  

---

## 回滚与更新

- **更新（推荐）**：在 `backend/` 执行 `./scripts/deploy.sh --with-git-pull`（或 `npm run deploy:prod:pull`）；已手动 `git pull` 后用 `./scripts/deploy.sh`（或 `npm run deploy:prod`）。  
- **更新（等价手写）**：`git pull` → `npm ci --omit=dev` → `npx prisma migrate deploy` → `npm run build` → `pm2 reload ecosystem.config.cjs --env production`。  
- **迁移失败**：勿强行改已发布迁移文件；见 `.cursor/project/README.md` Prisma 小节。

---

*文档版本：与 `backend_deployment_standard.md`、`backend/README.md` 部署章节配套使用。*
