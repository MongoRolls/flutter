# VPS 后端部署：简洁 Step-by-Step

**规范与默认决策**（必读）：`.cursor/project/后端部署规范.md`。

面向 **CentOS Stream 9**、**2C2G**、**PM2 + Podman 仅跑 PG/Redis**。可选 **全容器 API**（资源更紧）见 `backend/docker-compose.prod.yml` 与 `backend/README.md`。背景见 `VPS后端部署规划.md`。

### 部署顺序怎么排

| 路线            | 顺序                                                   | 说明                                                                                                                    |
| --------------- | ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| **默认（PM2）** | §1 → §2～§6 → §7                                       | 先在本机验证 `curl http://127.0.0.1:3000/health`，再配 Nginx。                                                          |
| **可先 HTTPS**  | §1 → **§7.1～§7.4**（占位）→ §2～§6 → **§7.5**（反代） | VPS 上尚未 `git clone`、没有 Node 时，也可先申请证书、浏览器看到占位 `ok`；**反代与 SSE** 必须等 **§6 PM2 起来** 再做。 |

全容器 + ghcr 镜像的替代路径（`docker-compose.prod.yml`、`deploy-podman.sh` 等）见 **`backend/README.md`**，本文默认路线不再单独展开。

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

安装 **Git**、**Node 20**、**PM2**、**Podman** 与 **podman-compose**（后者为必须：`podman compose` 依赖可用的 Compose 提供者，仅装 `podman` 会报 `looking up compose provider failed`）。

```bash
git --version
node -v   # 应为 v20.x
npm install -g pm2
sudo dnf install -y podman podman-compose
# 验证：podman --version && podman-compose --version
# 可选：podman compose version（与 podman-compose 等价，需已安装 podman-compose）
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
git clone --depth=1 --filter=blob:none --sparse <仓库 URL> keleme
cd keleme
git sparse-checkout init --cone
git sparse-checkout set backend
cd backend
```

继续 **§3**。

---

## 3. 起 PostgreSQL + Redis（仅容器）

**前提：** 当前目录为 `backend`，且存在项目自带的 `docker-compose.yml`（仅数据库）。Compose 文件名为 `docker-compose.yml` 是 OCI 惯例，**实际用 Podman 编排**。

```bash
podman-compose up -d
```

默认会映射 `5432`、`6379`。**生产**请在防火墙/安全组禁止公网访问这两个端口，仅本机连。

确认：

```bash
podman-compose ps
```

（若已安装 `podman-compose`，也可使用 `podman compose up -d` / `podman compose ps`，与上式等价。）

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

### 7.7 Nginx 故障与参考配置

- **占位仍返回 `ok`**：`443` 的 `location /` 仍是 `return 200 "ok"`，未 `proxy_pass` 到 `127.0.0.1:3000`。
- **`proxy_pass` duplicate**：同一 `location` 里写了两次 `proxy_pass`，多为 **`location /api/ai/chat {` 少了闭合 `}`**，导致与 `location /` 合并。用 `sudo cat -n ...` 核对括号。
- **`xy_set_header`**：拼写错误，应为 **`proxy_set_header`**。
- **`duplicate upstream`**：其它 `.conf` 已定义同名 `upstream`，可删掉参考文件里的 `upstream` 块，并把 `proxy_pass http://keleme_api` 改为 `http://127.0.0.1:3000`。

仓库内 **可直接覆盖** 的示例：`/.cursor/project/nginx-api.mongorolls.cn.conf`（与 `backend/README.md` 中反代片段一致；部署后执行 `nginx -t`）。

---

## 8. Flutter 生产包

构建时加上（域名换成你的）：

```bash
--dart-define=BACKEND_URL=https://api.你的域名
```

**示例（当前线上 API）：** `https://api.mongorolls.cn`

所有命令均在仓库 **`flutter/`** 目录下执行（`cd flutter`）。

**本地开发联调同一后端：**

```bash
flutter run -d macos --dart-define=BACKEND_URL=https://api.mongorolls.cn
# 或 Web：flutter run -d chrome --dart-define=BACKEND_URL=https://api.mongorolls.cn
```

**macOS 正式版打包（Release，产物在 `build/macos/Build/Products/Release/`）：**

```bash
flutter build macos --dart-define=BACKEND_URL=https://api.mongorolls.cn
```

**Android 正式 APK（与 CI 一致，可再加 `--split-per-abi`）：**

```bash
flutter build apk --dart-define=BACKEND_URL=https://api.mongorolls.cn
# 若同时需要 DeepSeek 代理，再加：--dart-define=DEEPSEEK_API_KEY=...
```

`BackendApiService` 会读取编译期 `BACKEND_URL`；若曾在 App 内保存过自定义 base URL（`SharedPreferences`），会优先用已保存值，联调前可在设置里清掉或卸载重装。

---

## 9. 以后更新后端

在 `backend/` 使用 `scripts/deploy.sh`（含 `git pull`、依赖、迁移、构建、`pm2 reload`）。

```bash
cd /opt/keleme/backend   # 或你的部署路径
./scripts/deploy.sh --with-git-pull
```

等价：`npm run deploy:prod:pull`。

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
