## Why

Flutter 客户端功能完整，但整体观感与以 Next.js 官网为参考的品牌视觉相比偏「工具感」：卡片层次、圆角/阴影、留白与动效节奏不一致，用户主观感受存在「官网精致、App 朴素」的落差。需要在**不改变业务逻辑**的前提下，以官网 **light** 主题下的 CSS 变量与 GlassCard 为**只读参考**，统一 Flutter 侧设计 token 与主题表现，降低跨端品牌落差。

## What Changes

- 产出 **web（只读）↔ Flutter** 设计 token 对应表（背景、语义色、圆角阶梯、边框/阴影策略），作为评审与实现依据；**不修改** `web/` 源码或构建。
- **仅 light**：收紧 `AppTheme` / `ColorScheme` / `TextTheme` 与 `Scaffold`、卡片表面色，使与官网 light 语义一致；**不实现** App 内深色模式。
- 统一通用容器（如 `GlassCard`）的圆角、阴影、边框透明度表达，收敛各屏重复的 `BoxDecoration`；玻璃态在性能受限时允许降级（纯色 + 轻阴影），功能不变。
- 在不大改信息架构与区块顺序的前提下，微调标题/正文层级与有限间距集合（如 8/12/16/24）。
- 对 Home、Settings、Community（或当前主导航三 Tab）进行**产品手动**真机/模拟器验收；保持可访问性底线（对比度、动态字体下主要布局不恶化）。
- **零新增** `pubspec.yaml` 依赖；不重写状态管理、不引入 Provider/Riverpod 等。

## Capabilities

### New Capabilities

- `design-tokens`: Flutter 与官网 light 的设计 token 文档化、全局主题（仅 light）、通用卡片/玻璃容器、排版与间距阶梯、抽检与可访问性底线；明确 web 侧文件仅作对照参考、实现路径均在 `flutter/`。

### Modified Capabilities

- （无）本变更不修改既有功能域（auth、community 等）的**行为**规格，仅新增横切「视觉与主题」能力；各 feature 屏幕仅作样式层刷新，不要求单独的 feature spec delta。

## Impact

- **Flutter**：`flutter/lib/core/theme/`（如 `app_theme.dart`、`AppColors`）、通用组件（如 `glass_card`）、主导航与各 feature 屏幕中的样式与局部间距；可选在 `.cursor/project` 或仓库约定位置存放 token 对照表（若项目选择放在 `flutter/` 下文档，以任务清单为准）。
- **后端**：无。
- **官网 `web/`**：**不在范围内**；仅允许只读引用 `web/app/globals.css`、`web/components/glass-card.tsx` 等作为对齐依据，不产生对 `web/` 的 PR 变更。
- **依赖**：无新包；CI 仍为 `flutter analyze` / `flutter test`。
