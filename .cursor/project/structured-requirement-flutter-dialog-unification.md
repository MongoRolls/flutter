# Flutter 弹窗统一与 UI 风格确认

> 统一全应用弹窗/底部面板视觉与交互，并与设计体系对齐。

## 1. 背景与动机

- **问题**：`flutter/lib` 内多处直接使用 `AlertDialog`、`showModalBottomSheet` 等，样式与圆角、按钮文案、标题层级、遮罩与动效不一致；与 `AppTheme` / `AppColors` 等既有设计语言未完全对齐，观感不统一。

## 2. 目标与非目标

| 目标 | 非目标 |
|------|--------|
| 定义并落地「标准弹窗」与「标准底部面板」的 UI 规范；**弹窗内容区为纯色卡片**（非毛玻璃） | 重写非弹窗类页面布局或全站导航 |
| **提供 2～3 种封装组件**（如居中确认、信息、底部面板等），业务按场景选用，不强制单一形态 | 引入新的状态管理包或路由框架 |
| 同步**一般性**更新 `openspec/specs/design-tokens` 与 `flutter/doc/design-tokens.md` | 修改 Next.js 官网（`web/`）弹窗 |

## 3. 范围与边界

- **产品/模块**：Flutter 客户端（`flutter/`）内所有用户可见的模态：`showDialog` / `AlertDialog` / `SimpleDialog`、`showModalBottomSheet`、以及同类确认/信息/选择场景。
- **技术边界**：仅 Flutter UI 与主题层；可新增 `common/widgets` 封装（如 `AppConfirmDialog`、`AppBottomSheet`）或在 `ThemeData`/`DialogTheme` 中集中配置。
- **明确不包含**：SnackBar/Toast（若已有 `app_toast` 可单独迭代）、系统级权限弹窗样式、非 Flutter 端。

## 4. 功能需求

| 编号 | 描述 | 优先级 |
|------|------|--------|
| FR-1 | 产出并评审「弹窗与底部面板」视觉规范：与 `AppColors`、`AppTheme`、圆角/阴影层级一致；**内容区纯色卡片**；区分信息、确认（destructive）、列表选择等类型。 | P0 |
| FR-2 | 提供三种封装 **`AppConfirmDialog` / `AppInfoDialog` / `AppModalSheet`**（见 §8）及主题绑定；覆盖确认（双按钮）、告知（单按钮）、底部长内容面板（含把手、标题区、安全区）。 | P0 |
| FR-3 | **一般性**更新 design tokens：`openspec/specs/design-tokens` 与 `flutter/doc/design-tokens.md`，纳入弹窗相关 token 与已拍板决策。 | P0 |
| FR-4 | 将现有散落调用（如 `home_screen`、`chat_screen`、`health_archive_screen`、`plan/*`、`add_contact_screen`、`debug_screen` 等）迁移到统一封装或 `DialogTheme`，消除明显风格漂移。 | P1 |
| FR-5 | 在 `flutter analyze` / 现有测试通过前提下，补充或更新最小 widget 测试（例如对话框按钮回调与主题色）。 | P2 |

## 5. 非功能需求（可选）

- **可访问性**：语义标签、按钮最小点击区域、与系统字体缩放协调。
- **一致性**：深色/浅色若已支持，弹窗需同步；动画时长与 `Material` 默认或产品约定一致。

## 6. 验收标准

对每条 **P0、P1** 至少一条：

```text
Scenario: 规范与主题对齐
  Given 设计规范文档或代码注释已写明弹窗/底栏 token
  When 在任一标准弹窗中查看背景、圆角、主按钮色
  Then 与 AppTheme/AppColors 约定一致，无硬编码散落的对比色例外（除非规范允许列表）

Scenario: 新确认框走统一入口
  Given 某功能需要「删除/放弃」类确认
  When 开发者使用统一封装或 DialogTheme 提供的 API
  Then 标题、正文、主/次按钮顺序与样式与其它确认框一致；**主按钮使用警示色**（destructive）

Scenario: 多风格组件可选
  Given 场景需要居中短确认或底部长内容
  When 开发者从 2～3 种封装中按文档选用
  Then 各场景使用对应组件，内容区均为**纯色卡片**而非毛玻璃

Scenario: 存量页面迁移可见
  Given 已列出的高频弹窗路径（如首页、聊天、健康档案、计划相关）
  When 用户打开对应弹窗
  Then 视觉与交互与统一规范一致，无混用旧 AlertDialog 裸样式（允许过渡期标注剩余清单）

Scenario: design tokens 同步
  Given OpenSpec 与 `flutter/doc/design-tokens.md` 已做一般性更新
  When 查阅弹窗相关 token（背景、圆角、destructive 等）
  Then 与代码中 `AppTheme`/封装组件一致，且两处文档口径一致
```

## 7. 假设、风险、开放问题

- **假设**：产品接受以 Material 3 为基础做定制，不强制 iOS 原生 `CupertinoAlertDialog` 为主路径（除非单独约定）。
- **风险**：迁移面广可能引入回归；需分批次合并与测试。

### 已确认决策（2026-03-27）

| # | 议题 | 结论 |
|---|------|------|
| 1 | 弹窗内容区背景 | **纯色卡片**（非毛玻璃；与页面内 `GlassCard` 装饰区可并存，弹窗本身不走玻璃效果） |
| 2 | 形态数量 | **允许 2～3 种风格并存**，封装为 **2～3 个可选组件**（如居中确认、信息、底部面板等），按场景选用 |
| 3 | 文档 | **一般性**更新 design tokens：`openspec/specs/design-tokens` + `flutter/doc/design-tokens.md` |
| 4 | 破坏性操作主按钮 | **可以**固定为警示色（destructive primary） |
| 5 | 遮罩与点击外部关闭 | **默认**（沿用 Flutter/Material 对 `showDialog` / `showModalBottomSheet` 的常规默认行为，不在本需求内自定义特殊规则） |

- **待确认**：无（上述五项已闭环）。若实现中发现「长内容 vs 底栏」边界歧义，可在评审时补一条选用表。

## 8. 三种标准弹窗：场景 · UI · 行为

以下与当前工程事实对齐：**仅 light**（`AppTheme.lightTheme`）、品牌色与圆角取自 `app_theme.dart`；弹窗内容区均为 **纯色卡片**（`AppColors.bgCard`），与页面内 `GlassCard` 的毛玻璃策略区分。

### 类型 A — 居中「确认」对话框（建议封装名：`AppConfirmDialog`）

| 维度 | 说明 |
|------|------|
| **适用场景** | 需要用户 **明确二选一** 的阻断式操作：删除记录/清空聊天/放弃编辑/覆盖数据/退出并丢失未保存内容等。项目内可参考：`chat_screen`、`health_archive_screen`、`plan` 相关确认、`debug_screen` 等现有 `AlertDialog` 确认流。 |
| **不适用** | 仅告知无操作分支；或内容超过约 **5～6 行** 且需滚动阅读；或含多控件表单（改用类型 C）。 |
| **UI** | **容器**：屏幕水平居中，最大宽度约 `min(400, 屏宽-48)`；圆角 **`AppRadius.xl`（22.4）** 或 **`AppRadius.x2l`（28.8）**（实现时二选一写死进封装）。背景 **`AppColors.bgCard`**，边框可用 **`AppColors.divider` 1px**（可选），阴影 **`AppShadows.card`**。**标题**：`titleLarge` / `titleMedium` 级，`AppColors.textPrimary`。**正文**：`bodyLarge` / `bodyMedium`，`textPrimary` / `textSecondary`。**按钮行**：主操作在 **右侧**（或纵向时主操作在上）；次操作「取消」用 **TextButton** 或 Outlined，主色 **`AppColors.blue`**；**破坏性操作**（删除、清空）主按钮 **`AppColors.red` 或 `redDeep` 背景 + 白字**（与已确认决策一致）。 |
| **表现行为** | 使用 **`showDialog`**。`barrierDismissible`、遮罩色等 **保持 Material 默认**（与已确认决策 #5 一致）。返回 **`Future<bool?>`**（true=确认，false=取消，null=遮罩关闭若允许）。打开后焦点在可聚焦控件上；避免在对话框内再叠多层模态。 |

### 类型 B — 居中「告知」对话框（建议封装名：`AppInfoDialog`）

| 维度 | 说明 |
|------|------|
| **适用场景** | **无需二选一**，仅需用户阅读后关闭：简短权限/功能说明、操作结果提示、轻量帮助。与类型 A 的区分：**没有取消/确认对立**，只有「知道了 / 好的」或单一主操作。 |
| **不适用** | 仍属高风险但需确认的 —— 用 **类型 A**；长文或图文 —— 优先 **类型 C** 或独立全屏页。 |
| **UI** | 与类型 A **同一套卡片几何与阴影**（纯色卡片、同圆角 token），减少视觉分叉。**单主按钮**（或主 + 次要链式链接若产品需要）；主按钮样式与主题 **`ElevatedButton`**（`AppColors.blue`）一致。**无** destructive 配色（除非文案本身是错误态且产品要求红色描边，一般不用）。 |
| **表现行为** | **`showDialog`**，默认行为同类型 A。返回 **`Future<void>`** 或用户点「知道了」后 `Navigator.pop`。 |

### 类型 C — 底部「内容与操作」面板（建议封装名：`AppModalSheet`）

| 维度 | 说明 |
|------|------|
| **适用场景** | **偏长内容**、列表选择、辅助信息展示、**二维码/短码展示**、多段设置项等；需要 **上滑手势/拖拽把手** 暗示可关闭。项目内可参考：`add_contact_screen` 好友短码、`home_screen` 等 **`showModalBottomSheet`** 用法。 |
| **不适用** | 一两句话的 Yes/No —— 用 **类型 A**；纯 Toast 级反馈 —— 用 **`app_toast`**，不用面板。 |
| **UI** | **容器**：顶角圆角 **`AppRadius.x2l`～`x3l`**（仅顶部圆角，与官网大圆角卡片意图一致），背景 **`AppColors.bgCard`**；顶部 **拖动指示条**（细圆角矩形，`AppColors.grey`/`divider`）。**标题栏**：可选左侧关闭、中间标题（`titleLarge`）。**内容区**：`padding` 优先 **16 / 24**，与 `design-tokens.md` 中间距阶梯一致；内容过高时 **内部滚动**，底部预留 **`SafeArea` + home indicator**。可选 **底栏主按钮**（固定不随内容滚动）。阴影可用 **`AppShadows.card`** 或略强调顶部投影。 |
| **表现行为** | 使用 **`showModalBottomSheet`**，`isScrollControlled: true`（当内容高度可能超过半屏时）。`barrierColor`、点遮罩关闭等 **默认**；若需 **拖拽下滑关闭**，在封装内用 `DraggableScrollableSheet` 或约定 `enableDrag: true`（与 Flutter 版本行为一致即可）。返回 **`Future<T?>`** 视业务传递选中项或 `null` 表示取消。 |

### 选用速查

| 用户任务 | 选用 |
|----------|------|
| 是否删除 / 是否放弃 / 是否覆盖 | **A** |
| 看完说明点「知道了」 | **B** |
| 展示码、长说明、列表、多控件 | **C** |

## 9. 参考

- `flutter/lib/core/theme/app_theme.dart`、`AppColors`、`AppRadius`、`AppShadows`
- `flutter/lib/common/widgets/glass_card.dart`（页面内卡片参考；**弹窗内容区不用毛玻璃**）
- `openspec/specs/design-tokens/`、`flutter/doc/design-tokens.md`
- 代码中 `showDialog` / `showModalBottomSheet` 出现位置（全库检索）
