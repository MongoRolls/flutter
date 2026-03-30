## Why

Flutter 应用内多处直接使用 `AlertDialog`、`showModalBottomSheet` 等，圆角、按钮层级、标题与正文样式、遮罩行为不一致，与 `AppTheme` / `AppColors` 及既有设计体系未对齐，影响观感与可维护性。需要在不引入新状态管理或路由框架的前提下，用少量标准封装与文档化 token 统一模态体验。

## What Changes

- 定义并落地三种标准模态封装：**`AppConfirmDialog`**（居中双选确认）、**`AppInfoDialog`**（居中告知）、**`AppModalSheet`**（底部长内容/列表等）；弹窗内容区为**纯色卡片**（`AppColors.bgCard`），非毛玻璃。
- 在 `ThemeData` / `DialogTheme` 等层面按需绑定，使新代码默认走统一入口；破坏性操作主按钮使用 **destructive** 色（与已确认决策一致）。
- **一般性**更新 `openspec/specs/design-tokens` 与 `flutter/doc/design-tokens.md`，纳入弹窗/底栏相关 token 与选用说明。
- **P1**：将现有散落调用（如 `home_screen`、`chat_screen`、`health_archive_screen`、`plan/*`、`add_contact_screen`、`debug_screen` 等）分批迁移到统一封装或主题配置，消除明显风格漂移。
- **P2**：在 `flutter analyze` / 现有测试通过前提下，补充最小 widget 测试（如按钮回调与主题色）。
- **明确不包含**：`web/` 官网；SnackBar/Toast 单独迭代；系统权限对话框样式定制。

## Capabilities

### New Capabilities

- `modal-dialogs`: Flutter 应用内标准居中对话框（确认 / 告知）与标准底部模态面板的视觉、交互与选用规则；与 `showDialog` / `showModalBottomSheet` 的集成方式及存量迁移验收口径。

### Modified Capabilities

- `design-tokens`: 在现有 light 主题与 GlassCard 等要求之上，增加**模态层**相关 token 与文档要求（背景、圆角阶梯、destructive 主按钮、底栏顶角与把手等），并与 `modal-dialogs` 实现保持一致。

## Impact

- **Flutter**：`flutter/lib/core/theme/app_theme.dart`（`DialogTheme` 等）、新增 `flutter/lib/common/widgets/` 下封装（名称以实现为准）、多处 feature 屏幕中 `showDialog` / `showModalBottomSheet` 调用替换或收敛。
- **文档**：`openspec/specs/design-tokens/spec.md`（delta）、`flutter/doc/design-tokens.md`。
- **后端**：无。
- **依赖**：无新版本级依赖要求；沿用现有 Material 3 与工程 lint/测试命令。
