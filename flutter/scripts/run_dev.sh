#!/usr/bin/env bash
# 使用 dart_defines/dev.env 启动 Flutter，等价于本地 API 联调。
# 用法（在 flutter/ 目录下）：
#   ./scripts/run_dev.sh              # 默认 -d macos
#   ./scripts/run_dev.sh chrome
#   ./scripts/run_dev.sh macos -v
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DEVICE="${1:-macos}"
shift || true
exec flutter run -d "$DEVICE" --dart-define-from-file=dart_defines/dev.env "$@"
