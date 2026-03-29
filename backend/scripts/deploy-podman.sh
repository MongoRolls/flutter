#!/usr/bin/env bash
# KeLeME backend — 生产环境更新（Podman Compose 全栈：api + postgres + redis）
# 前提：backend/.env 已配置；KELEME_BACKEND_IMAGE 指向 ghcr.io 等仓库时为镜像部署。
#
# 用法（在 backend/ 下）：
#   ./scripts/deploy-podman.sh              # up -d + prisma migrate deploy
#   ./scripts/deploy-podman.sh --pull       # 先 pull 镜像（用 registry 时发版常用）
#
# 环境变量：
#   COMPOSE_FILE  默认 docker-compose.prod.yml
#   若未装独立 podman-compose，脚本会尝试 Podman 4+ 自带的「podman compose」（空格）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

if command -v podman-compose >/dev/null 2>&1; then
  COMPOSE=(podman-compose -f "$COMPOSE_FILE")
elif podman compose version >/dev/null 2>&1; then
  COMPOSE=(podman compose -f "$COMPOSE_FILE")
else
  echo "未找到 podman-compose 或可用的「podman compose」。可安装: pip install podman-compose；或升级 Podman 4+。" >&2
  exit 1
fi

if [[ "${1:-}" == "--pull" ]]; then
  echo "==> compose pull"
  "${COMPOSE[@]}" pull
fi

echo "==> compose up -d"
"${COMPOSE[@]}" up -d

echo "==> prisma migrate deploy (api 容器)"
# 依赖 compose 中 depends_on + healthcheck，一般已就绪；略等再执行迁移更稳
sleep 3
"${COMPOSE[@]}" exec -T api npx prisma migrate deploy

echo "==> deploy-podman finished"
