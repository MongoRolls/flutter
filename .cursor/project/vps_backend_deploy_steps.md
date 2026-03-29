# VPS 后端部署：简洁 Step-by-Step

**规范与默认决策**（必读）：`.cursor/project/backend_deployment_standard.md`。

面向 **CentOS Stream 9**、**2C2G**、**PM2 + Docker/Podman 仅跑 PG/Redis**。可选 **全容器** 见 `backend/docker-compose.prod.yml` 与 `backend/README.md`。背景见 `vps_backend_deployment_plan.md`。

### 部署顺序怎么排

| 路线 | 顺序 | 说明 |
|------|------|------|
| **默认（PM2）** | §1 → §2～§6 → §7 | 先在本机验证 `curl http://127.0.0.1:3000/health`，再配 Nginx。 |
| **可先 HTTPS** | §1 → **§7.1～§7.4**（占位）→ §2～§6 → **§7.5**（反代） | VPS 上尚未 `git clone`、没有 Node 时，也可先申请证书、浏览器看到占位 `ok`；**反代与 SSE** 必须等 **§6 PM2 起来** 再做。 |
| **B：Podman 全栈 + ghcr 镜像** | §1 → **§B** → §7（反代目标改为 3000 上 API 容器，与 PM2 相同） | **无需整仓 `git clone`**：用 `scp` 或浅克隆只放 `backend/` 必要文件 + `podman pull` 镜像。详见 **§B**。 |

---

## B. Podman 全栈 + 镜像（免整仓 clone）

**前提**：仓库 `main` 已启用 **GitHub Actions** `.github/workflows/backend-docker.yml`，镜像在 ghcr.io（如 `ghcr.io/<owner>/<repo>/keleme-backend:latest`）。**2C2G** 上资源比「仅 DB 容器 + PM2」更紧，自行评估。

### B.1 服务器安装

```bash
sudo dnf install -y podman podman-compose
# 可选：不装 Node / PM2（本路线 API 在容器内）
```

### B.2 准备目录与文件（无需 git clone 整仓）

在 VPS 上建目录（例如 `/opt/keleme-backend`），从本机 **scp** 或 **只 clone 仓库后只保留** 以下文件即可：

- `backend/docker-compose.prod.yml`
- `backend/scripts/deploy-podman.sh`（`chmod +x`）

### B.3 配置 `.env`

在**同一目录**（与 `docker-compose.prod.yml` 并列）创建 `.env`，可参考仓库内 `backend/.env.example`，至少包含：

- `NODE_ENV=production`
- `JWT_SECRET` / `JWT_REFRESH_SECRET` / `DEEPSEEK_API_KEY` / `CORS_ORIGIN`
- `KELEME_BACKEND_IMAGE=ghcr.io/<你的仓库小写路径>/keleme-backend:latest`
- `POSTGRES_PASSWORD`（强密码；compose 内 `postgres` 与 `api` 的 `DATABASE_URL` 会使用）

**若镜像仓库为私有**：先 `podman login ghcr.io`（用户名 GitHub，密码为 PAT）。

### B.4 启动与迁移

```bash
cd /opt/keleme-backend   # 你的目录
./scripts/deploy-podman.sh --pull
curl -s http://127.0.0.1:3000/health
```

后续更新：在 CI 已推送新镜像后，在同一目录执行 `./scripts/deploy-podman.sh --pull` 即可。

### B.5 Nginx

与 **§7.5** 相同，反代到 `127.0.0.1:3000`（API 容器映射端口）。SSE 段与 `backend/README.md` 一致。

**勿与 PM2 同时占用 3000 端口**：若本机曾用 PM2 跑 API，需先停 PM2 再 `deploy-podman`。

---

## 0. 本机 / 面板准备好

- VPS 公网 IP、SSH 能登录  
- 域名（可选）：`api.你的域名` → A 记录指向该 IP  
- 随机串：`JWT_SECRET`、`JWT_REFRESH_SECRET`（各 ≥32 字符）、`DEEPSEEK_API_KEY`（`sk-` 开头）

---

## 1. 服务器基础（SSH 里执行）

```bash
dnf update -y
timedatectl
# 防火墙：放行 22、80、443（工具随发行版，如 firewalld / 云安全组）
# 建议加 swap 1～2G（2G 内存机器）
```

安装 **Git**、**Node 20**、**PM2**、**Podman**（或 Docker）+ compose：

```bash
git --version
node -v   # 应为 v20.x
npm install -g pm2
sudo dnf install -y podman podman-compose
# 使用 compose 时：podman compose ... 或 podman-compose ...
```

---

## 2. 拉代码（`git clone`）

```bash
cd /opt
git clone <HTTPS 或 SSH> keleme
cd keleme/backend
```

**HTTPS 注意：** GitHub **不能再用账户密码**，密码处应填 **Personal Access Token（PAT）**，或改用 **SSH 公钥**（`git@github.com:用户/仓库.git`）。

**仓库大、clone 中途断线（`RPC failed` / `Connection reset`）时可试：**

```bash
git config --global http.postBuffer 524288000
git config --global http.version HTTP/1.1
git clone --depth 1 <地址> keleme
```

继续 **§3**。

---

## 3. 起 PostgreSQL + Redis（仅容器）

**前提：** 当前目录为 `backend`，且存在项目自带的 `docker-compose.yml`（仅数据库）。

```bash
# Docker 示例；若用 Podman，把 docker 换成 podman
docker compose up -d
```

默认会映射 `5432`、`6379`。**生产**请在防火墙/安全组禁止公网访问这两个端口，仅本机连。

确认：

```bash
docker compose ps
```

---

## 4. 环境变量

```bash
cp .env.example .env
nano .env   # 或 vim
```

至少设置（与 `docker-compose.yml` 默认一致时示例）：

```env
NODE_ENV=production
PORT=3000
DATABASE_URL="postgresql://keleme:keleme_dev_password@127.0.0.1:5432/keleme_db"
REDIS_URL="redis://127.0.0.1:6379"
JWT_SECRET="<≥32 字符随机>"
JWT_REFRESH_SECRET="<≥32 字符随机>"
DEEPSEEK_API_KEY="sk-..."
CORS_ORIGIN="https://你的前端域名"
```

生产请把 `docker-compose.yml` 里默认密码改成强密码，并同步改 `DATABASE_URL`。

---

## 5. 安装依赖、迁移、构建

```bash
npm ci --omit=dev
npx prisma generate
npx prisma migrate deploy
npm run build
```

---

## 6. PM2 启动

```bash
pm2 start ecosystem.config.cjs --env production
pm2 save
pm2 startup
# 按屏幕提示执行一条 sudo 命令
```

验证：

```bash
curl -s http://127.0.0.1:3000/health
```

---

## 7. Nginx + HTTPS（对外用域名）

**前提：** `api.你的域名` 已在 DNS 做 **A 记录** 指向 VPS **公网 IP**（与 `ssh` 所用 IP 一致）；云安全组 / 本机防火墙放行 **80、443**。

### 7.1 安装 Nginx 与 Certbot

```bash
sudo dnf install -y nginx certbot python3-certbot-nginx
sudo systemctl enable --now nginx
```

### 7.2 先写带 `server_name` 的占位站点（避免 Certbot 装不上证书）

默认 `nginx` 可能没有 `server_name api.你的域名`，直接跑 Certbot 容易出现：**证书已签发，但 `Could not install certificate`。** 先增加最小 `server` 再申请/安装：

```bash
# 把 api.你的域名 换成真实域名，例如 api.example.com
sudo tee /etc/nginx/conf.d/api.conf <<'EOF'
server {
    listen 80;
    server_name api.你的域名;
    location / {
        default_type text/plain;
        return 200 "ok\n";
    }
}
EOF

sudo nginx -t && sudo systemctl reload nginx
```

### 7.3 申请证书并挂到 Nginx

```bash
sudo certbot --nginx -d api.你的域名
```

按提示填写邮箱、同意条款。若已成功签发但提示 **无法自动 install**，证书文件仍在 `/etc/letsencrypt/live/api.你的域名/`，执行：

```bash
sudo certbot install --cert-name api.你的域名 --nginx
```

仍失败时，用下面替换 `server_name` 与 `conf` 文件名后整段覆盖 **7.2** 的配置（`fullchain.pem` / `privkey.pem` 路径以 `certbot` 成功时提示为准）：

```nginx
server {
    listen 80;
    server_name api.你的域名;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.你的域名;
    ssl_certificate     /etc/letsencrypt/live/api.你的域名/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.你的域名/privkey.pem;

    location / {
        default_type text/plain;
        return 200 "ok\n";
    }
}
```

若 `nginx -t` 报缺少 `options-ssl-nginx.conf`，可先删除 Certbot 生成的 `include` 行，仅保留 `ssl_certificate` 两行。然后 `nginx -t && sudo systemctl reload nginx`。

### 7.4 验证 HTTPS（占位阶段）

```bash
curl -sI https://api.你的域名/
```

浏览器访问应能看到占位 **`ok`**。此时尚未反代到 Node，**没有**后端是正常的。

### 7.5 反代到 PM2（须在 §6 之后）

当 `curl -s http://127.0.0.1:3000/health` 已通，编辑该域名的 **443** `server`（及如需统一的 `upstream`）：

1. **`location /`**：`proxy_pass` 到 `http://127.0.0.1:3000`（推荐与 `backend/README.md` 中 **`upstream keleme_api`** 示例一致）。  
2. **另加 `location /api/ai/chat`**：关闭 `proxy_buffering`、拉长 `proxy_read_timeout`（SSE 流式）— **全文见 `backend/README.md` →「PM2 + Nginx 反向代理」**。  

```bash
sudo nginx -t && sudo systemctl reload nginx
curl -s https://api.你的域名/health
```

### 7.6 续期自检（可选）

```bash
sudo certbot renew --dry-run
```

---

## 8. Flutter 生产包

构建时加上（域名换成你的）：

```bash
--dart-define=BACKEND_URL=https://api.你的域名
```

---

## 9. 以后更新后端

**PM2 路线（默认）**：在 `backend/` 使用 `scripts/deploy.sh`（含 `git pull`、依赖、迁移、构建、`pm2 reload`）。

```bash
cd /opt/keleme/backend   # 或你的部署路径
./scripts/deploy.sh --with-git-pull
```

等价：`npm run deploy:prod:pull`。

**路线 B（Podman 全栈 + ghcr）**：无需 `git pull`，CI 已推送新镜像后：

```bash
cd /opt/keleme-backend   # §B 中目录
./scripts/deploy-podman.sh --pull
```

若已在该目录**手动** `git pull`，可只执行：

```bash
./scripts/deploy.sh
```

等价：`npm run deploy:prod`。

**手写等价**：

```bash
cd /opt/keleme/backend
git pull
npm ci --omit=dev
npx prisma generate
npx prisma migrate deploy
npm run build
pm2 reload ecosystem.config.cjs --env production
```

---

## 若 AI 聊天（SSE）异常

编辑 `ecosystem.config.cjs`：`exec_mode: 'fork'`，`instances: 1`，再 `pm2 reload ...`。详见 `backend/README.md`。
