#!/usr/bin/env bash
# KeLeME backend — 生产环境更新脚本（PM2 路径）
# 用法：
#   ./scripts/deploy.sh                    # 当前目录需为 backend/ 或从 backend/ 调用
#   ./scripts/deploy.sh --with-git-pull  # 先 git pull 再部署（VPS 常用）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "${1:-}" == "--with-git-pull" ]]; then
  echo "==> git pull"
  git pull
fi

echo "==> npm ci"
npm ci --omit=dev

echo "==> prisma generate + migrate deploy"
npx prisma generate
npx prisma migrate deploy

echo "==> build"
npm run build

echo "==> pm2 reload"
pm2 reload ecosystem.config.cjs --env production

echo "==> deploy finished"
