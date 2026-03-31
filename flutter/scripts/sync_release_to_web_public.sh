#!/usr/bin/env bash
# 将 Flutter Release 产物同步到 ../web/public（MVP 官网直链下载）
# 用法：在 flutter/ 目录执行 ./scripts/sync_release_to_web_public.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_PUBLIC="$(cd "$ROOT/../web/public" && pwd)"

echo "==> macOS Release + zip"
flutter build macos --release
ditto -c -k --keepParent \
  "$ROOT/build/macos/Build/Products/Release/渴了么.app" \
  "$WEB_PUBLIC/ke-le-me-macos.zip"

echo "==> Android Release（仅 arm64-v8a，体积较小）"
flutter build apk --release --split-per-abi \
  --dart-define=BACKEND_URL="${BACKEND_URL:-https://api.mongorolls.cn}"
cp "$ROOT/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
  "$WEB_PUBLIC/ke-le-me-release.apk"

echo "==> iOS IPA（需 Xcode 签名与描述文件；失败可跳过，稍后手动 build ipa 再复制）"
set +e
flutter build ipa --release \
  --dart-define=BACKEND_URL="${BACKEND_URL:-https://api.mongorolls.cn}"
IPA_STATUS=$?
set -e
if [[ $IPA_STATUS -eq 0 ]]; then
  # 归档成功但导出失败时可能无 .ipa；pipefail 下空 glob 会令命令替换失败并触发 set -e
  IPA="$(ls -1 "$ROOT/build/ios/ipa/"*.ipa 2>/dev/null | head -1)" || true
  if [[ -n "${IPA:-}" ]]; then
    cp "$IPA" "$WEB_PUBLIC/ke-le-me-ios.ipa"
    echo "    已复制: ke-le-me-ios.ipa"
  fi
else
  echo "    跳过 IPA（请在本机配置 Apple 开发者 Team/设备后执行: flutter build ipa）"
fi

echo "==> 完成。输出目录: $WEB_PUBLIC"
ls -lh "$WEB_PUBLIC"/*.apk "$WEB_PUBLIC"/*.zip 2>/dev/null || true
ls -lh "$WEB_PUBLIC"/*.ipa 2>/dev/null || true
