# Backend 容器：macOS + Podman 排障（Step-by-Step）

面向：**本机想 `podman build` / `podman compose` 试 backend**，但出现 `Cannot connect to Podman`、`gvproxy`、`podman-compose: command not found` 等情况。

---

## Step 0 — 确认现状

在 `backend/` 外任意目录执行：

```bash
which podman docker podman-compose
podman machine list
podman info
```

| 现象 | 含义 |
|------|------|
| 仅有 `podman`，无 `docker` | 需修好 Podman machine，或安装 [Docker Desktop](https://www.docker.com/products/docker-desktop/) 做本机构建 |
| `podman info` 报 Cannot connect | **虚拟机未启动或已损坏** |
| `command not found: podman-compose` | 正常：改用 **`podman compose`**（Podman 4+ 自带，中间有空格） |

---

## Step 1 — 先尝试「只启动」已有 machine

```bash
podman machine list
podman machine start
```

成功后再：

```bash
cd /path/to/repo/backend
podman build -t keleme-backend:local .
```

若 **`start` 成功** 但 **`build` 仍失败**，记下完整报错进入 Step 3。

---

## Step 2 — 仍报 socket / identity / gvproxy：重置 machine（会删掉该 VM 内数据）

**注意**：仅影响 Podman 虚拟机里的容器/镜像，**不删**你 Mac 上的项目文件。

```bash
podman machine stop
podman machine rm -f podman-machine-default
podman machine init
podman machine start
podman info
```

然后再：

```bash
cd backend
podman build -t keleme-backend:local .
```

若 `machine start` 仍报 **`gvproxy` socket**：

- 退出 VPN / 代理软件后重试；
- 重启 Mac 后再 `podman machine start`；
- 升级 Podman：`brew upgrade podman`；
- 仍不行：改用 Docker Desktop 本机构建，或只在 **CI / Linux VPS** 上构建。

---

## Step 3 — 验证镜像与全栈（不依赖 `podman-compose`）

```bash
cd backend

# Compose（二选一，不要装 podman-compose 也行）
podman compose version
podman compose -f docker-compose.prod.yml -f docker-compose.prod.local.yml up -d --build

# 等 PG/Redis healthy 后（约十几秒）
./scripts/deploy-podman.sh
curl -s http://127.0.0.1:3000/health
```

收尾：

```bash
podman compose -f docker-compose.prod.yml -f docker-compose.prod.local.yml down
```

---

## Step 4 — 可选：安装 Docker Desktop 专用于本机调试

若 Podman 在 macOS 上反复异常，可安装 Docker Desktop，用：

```bash
cd backend
docker build -t keleme-backend:local .
docker compose -f docker-compose.prod.yml -f docker-compose.prod.local.yml up -d --build
```

生产/VPS 仍可按文档使用 Podman。

---

## 与仓库脚本的对应关系

| 命令 | 说明 |
|------|------|
| `podman compose` | 推荐，替代独立 `podman-compose` 包 |
| `./scripts/deploy-podman.sh` | 已自动在 `podman-compose` 与 `podman compose` 间选择 |

---

*若 CI（`backend-docker.yml）构建通过而本机失败，优先按 Step 2 修 machine 或 Step 4 用 Docker。*
