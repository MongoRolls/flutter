---
name: flutter-release-web-public
description: KeLeME Flutter 发布流程——在 flutter/ 构建 macOS 与 Android Release，并将产物同步到 web/public 供官网直链下载。当用户要求「发布」「打 release」「同步到官网」「产物进 web/public」「构建 apk/macos 到 public」或需要 AI 自动执行该流水线时使用。
license: MIT
metadata:
  author: keleme
  version: "1.0"
---

# Flutter Release → web/public（KeLeME）

本仓库为 monorepo：**Flutter 客户端**在 `flutter/`，**官网静态资源**在 `web/public/`。将 Android / macOS Release 产物写入 `web/public` 的**标准做法**是运行仓库内脚本，不要手写复制路径。

## 何时触发

- 用户要把 **APK / macOS zip** 放到官网可下载目录
- 用户说「构建安卓和 macOS」「release 同步到 web」「public 里更新安装包」
- 与 CI 对齐的本地发布前验证（产物名与脚本一致）

## 前置条件（由执行环境满足）

| 目标 | 要求 |
|------|------|
| macOS `.zip` | 在本机 macOS 上执行，已安装 Xcode / `flutter build macos` 可用 |
| Android `.apk` | Android SDK 已配置，`flutter doctor` 中 Android  toolchain 正常 |
| iOS `.ipa` | 可选；脚本会尝试 `flutter build ipa`，无签名时会跳过并提示 |

## 标准命令（必须由 AI 在终端执行）

工作目录：**`flutter/`**（所有 `flutter` 命令与脚本均相对此目录）。

```bash
cd /Users/admin/Desktop/code/keleme/flutter
./scripts/sync_release_to_web_public.sh
```

可选：覆盖后端地址（与脚本内默认一致时可省略）：

```bash
cd /Users/admin/Desktop/code/keleme/flutter
BACKEND_URL="https://api.mongorolls.cn" ./scripts/sync_release_to_web_public.sh
```

脚本会依次：

1. `flutter build macos --release` → 用 `ditto` 打 zip  
2. `flutter build apk --release --split-per-abi`（含 `--dart-define=BACKEND_URL=...`）  
3. 尝试 `flutter build ipa`（失败则跳过）

## 输出位置与文件名（固定）

根目录为 **`web/public/`**（即仓库 `keleme/web/public`）：

| 文件 | 说明 |
|------|------|
| `ke-le-me-macos.zip` | macOS 应用压缩包 |
| `ke-le-me-release.apk` | arm64-v8a APK（split 产物复制） |
| `ke-le-me-ios.ipa` | 仅当 IPA 构建成功时生成 |

完成后可列出确认：

```bash
ls -lh /Users/admin/Desktop/code/keleme/web/public/ke-le-me-*
```

## 与「仅运行 App」的区别

- **`flutter run -d macos` / `flutter run -d android`**：本地调试，**不会**把包写入 `web/public`。  
- **本 skill 指向的流程**：Release 构建 + **同步到 `web/public`**，供 Next.js 站点直链。

若用户既要本机试跑又要官网包，先 `flutter run` 验证，再执行 `./scripts/sync_release_to_web_public.sh`。

## AI 执行注意

1. 使用**绝对路径** `cd` 到 `flutter/`，避免 cwd 错误。  
2. 构建耗时较长：macOS + APK 可能数分钟，应使用足够长的终端等待或后台策略。  
3. 失败时根据日志判断：缺 Xcode / Android SDK / 签名 → 向用户说明阻塞原因，不要伪造 `web/public` 文件。  
4. 不要修改 `web/public` 里与脚本无关的静态资源，除非用户另有要求。

## 与项目文档的对应关系

`AGENTS.md` 中的 `./scripts/sync_release_to_web_public.sh` 路径相对于 **`flutter/`**；本 skill 与之一致。
