# Flutter 客户端 UI 与官网（web）视觉对齐

> 以 Next.js 官网为参考，系统性提升 Flutter 端视觉层次与组件一致性。

## 1. 背景与动机

- **问题**：当前 Flutter 客户端功能完整，但整体观感与官网（`web/`）相比偏「工具感」：卡片层次、圆角/阴影、留白与动效节奏与官网营销页不一致；用户主观感受为「web 端设计更优秀」。
- **动机**：在不改变业务逻辑的前提下，统一品牌感知，降低「官网很精致、App 很朴素」的落差。

## 2. 目标与非目标

| 目标 | 非目标 |
|------|--------|
| 以 `web/app/globals.css` 中 KeLeME token（如 `--kelem-bg`、`--radius`、语义色）与 `web/components/glass-card.tsx` 等为**单一事实来源**，在 Flutter 中映射或对齐等价视觉（圆角阶梯、边框/阴影、玻璃态层次）。 | 重写业务逻辑、更换状态管理方式、引入 Provider/Riverpod 等。 |
| 建立/收紧 Flutter 侧 **Design tokens**（`AppColors` / `AppTheme` / 间距与圆角常量），使新页面默认「像官网」。 | 1:1 复刻官网所有交互动画（官网为桌面+营销场景，移动端需裁剪）。 |
| **不大改布局**：以换色、圆角、阴影、卡片容器与排版微调为主，不重组页面信息架构与区块顺序。 | 改造 Next.js 官网代码或 `web/` 构建流程（本需求**默认不含** `web/`，除非单独立项）。 |
| **仅 light**：不对齐、不实现 App 内深色模式（与当前 web 的 `.dark` 能力无关）。 | 新增 `pubspec.yaml` 依赖（**零新依赖**，见 §7）。 |

## 3. 范围与边界

- **产品/模块**：`flutter/` 内全局主题、通用容器（如 `GlassCard` 类组件）、AppBar/底部导航、主要 feature 屏幕的**样式层**（布局结构保持）。
- **技术边界**：仅 Flutter/Dart 与**现有**依赖（`google_fonts`、现有 widgets）；**不新增** pub 包；不新增后端依赖。
- **明确不包含**：OpenSpec 规格合并、后端 API 变更、推送/通知逻辑变更；**不包含**对 web 深色主题的客户端实现。

## 4. 功能需求

| 编号 | 描述 | 优先级 |
|------|------|--------|
| FR-1 | **Token 对齐文档化**：列出 web 端 `:root`（light）与 `@theme` 中与品牌相关的变量（背景、主色、圆角 `--radius`、边框 `--border` 等），与 Flutter `AppColors`/`ThemeData` 字段一一对应表（允许因平台差异 ±1px 或近似色）。 | P0 |
| FR-2 | **全局主题（仅 light）**：`AppTheme` 中 `scaffold`、卡片表面色、`ColorScheme` 与文字层级与官网 **light** 主题语义一致；**不要求** Flutter 实现深色模式。 | P0 |
| FR-3 | **容器组件**：统一「卡片」圆角（参考官网 `rounded-2xl`、阴影 `shadow-[0_2px_12px_...]`）、边框透明度（如 `border-white/60` 在 Flutter 中的等价或降级实现），并替换或收敛各屏重复的 `BoxDecoration`。 | P1 |
| FR-4 | **排版与间距**：在**不大改布局**前提下，标题/正文字号阶梯与 `TextTheme` 对齐官网层级；列表与区块垂直间距采用有限集合（如 8/12/16/24）。 | P1 |
| FR-5 | **核心屏抽检**：至少 Home、Settings、Community（或当前主导航三 Tab）由**产品手动查看**真机/模拟器，确认品牌观感可接受。 | P1 |
| FR-6 | **可访问性底线**：对比度不低于现有 WCAG 实践，动态字体下主要布局不溢出（与现网一致或更好）。 | P2 |

## 5. 非功能需求（可选）

- **性能**：避免全屏 `BackdropFilter` 层叠过多导致掉帧；复杂屏用 `RepaintBoundary` 隔离；若模糊代价高，采用 §9 所述降级且**不影响功能**。
- **可维护性**：样式常量集中在 theme/扩展，不在业务 `build` 里散落魔法数字。
- **国际化**：样式改动不改变字符串含义；中文与数字字体策略保持与 `AGENTS.md` 一致（Noto Sans SC / Space Mono）。

## 6. 验收标准

对每条 **P0、P1** 至少一条：

```text
Scenario: Token 表可评审
  Given 已产出 web↔Flutter token 对应表（含圆角与阴影策略）
  When 评审会议对照 web 开发者工具中的计算样式（light）
  Then 主色、背景、卡片、主文案色与官网 light 主题无肉眼冲突

Scenario: 全局主题生效
  Given 冷启动 App
  When 进入任意带 Scaffold 的屏幕
  Then 背景色与 AppBar/卡片表面与 token 表一致，无大面积硬编码旧色

Scenario: 卡片视觉统一
  Given 使用统一 Glass/卡片组件的列表或区块
  When 用户滚动浏览
  Then 圆角与阴影与官网 GlassCard（light）意图一致，且无同一屏多种不兼容卡片样式

Scenario: 产品手动验收
  Given 完成 Home / Settings / Community 等约定范围的样式刷新
  When 产品在实际设备上逐屏查看
  Then 产品确认观感可发布，或列出有限条可接受偏差（以不影响功能为前提）
```

## 7. 假设、风险与已确认决策

- **假设**：官网 `web/app/globals.css`（`:root` light）与 `web/components/glass-card.tsx` 代表当前品牌权威；Flutter 仅对齐 **light**。
- **风险**：玻璃态（`backdrop-blur`）在部分 Android 设备成本高；采用纯色 + 轻阴影降级时，**允许与 web 视觉不完全一致**，以流畅与功能为准。

**已确认（原「待确认」）**

| # | 内容 |
|---|------|
| 1 | **不需要**在 Flutter 中支持深色模式；不对齐 web `.dark`。 |
| 2 | 「参考 frontend-design 等高完成度 UI 原则」**是**——层次、间距、少装饰噪音；作约束而非实现依赖。 |
| 3 | **布局不大改**：不重组 IA、不改主要区块顺序；仅样式与局部间距/圆角层级调整。 |
| 4 | **零新依赖**：不新增 `pubspec.yaml` 包。 |
| 5 | **验收**：由**产品手动查看**设备得出结论，不要求设计 checklist 或强制并排截图流程。 |

## 8. 当前 web 页面风格（摘要，对齐用）

以下描述 **light** 下官网侧已落地的风格，便于 Flutter 对照；完整源文件仍以 `web/app/globals.css`、`web/components/glass-card.tsx` 为准。

### 8.1 技术栈与结构

- **Tailwind CSS v4** + **shadcn/tailwind** 语义 token；KeLeME 在 `@theme inline` 中扩展 `--color-kelem-*`，并在 `:root` 中给出原始色与 shadcn 映射。
- **基础圆角**：`--radius: 1rem`（16px），并衍生 `--radius-sm`～`--radius-4xl`（按比例缩放）。
- **页面基座**：`body` 使用 `bg-background text-foreground antialiased`；`html` 默认 `color-scheme: light`。

### 8.2 Light 品牌色与语义色（`:root` 摘录）

| Token / 用途 | 值（摘要） |
|--------------|------------|
| `--kelem-bg` | `#f5f8ff` |
| `--kelem-card` | `#ffffff` |
| `--kelem-sky` / 主色 | `#29b6f6` |
| `--kelem-sky-deep` | `#0288d1` |
| `--kelem-sky-bright` | `#4fc3f7` |
| `--kelem-green` | `#4caf50` |
| `--kelem-orange` | `#ff9800` |
| `--kelem-pink` | `#ff6b9d` |
| `--kelem-text-secondary` | `#546e7a` |
| `--kelem-text-hint` | `#90a4ae` |
| `--foreground` | `#1a2340` |
| `--muted` | `#eff4fb` |
| `--border` / `--input` | `#e8eff5` |
| `--secondary` | `#e3f2fd`（`--secondary-foreground`: `#0288d1`） |

### 8.3 GlassCard 组件（营销页卡片）

- **圆角**：`rounded-2xl`（对应 Tailwind 默认 1rem，与 `--radius` 一致）。
- **Light**：`border border-white/60`、`bg-card/95`、`shadow-[0_2px_12px_rgba(0,0,0,0.06)]`、`backdrop-blur-md`、内边距 `p-4`（`sm:p-6`）。
- **说明**：组件源码中含 `dark:` 变体；本需求 **Flutter 不对齐 dark**，仅将 **light** 侧视觉作为目标。

### 8.4 其它页面级特征（供审美一致，非强制逐像素）

- Hero 等区域使用 `.kelem-bubble` 等装饰（径向渐变 + 浮动动画）；Flutter **不要求**复刻，除非产品单点要求。
- `prefers-reduced-motion` 下 web 会减弱动效；Flutter 若新增动画，建议同样尊重系统减少动画（可选，P2）。

## 9. Flutter 能力与双端差异

在 **不大改布局、零新依赖** 前提下，下列差异**允许存在**；以**不损害功能、不显著卡顿**为底线，视觉以「接近官网 light」为方向而非数学级像素一致。

| 能力 | Web（CSS） | Flutter | 处理原则 |
|------|------------|---------|----------|
| 背景模糊 / 玻璃态 | `backdrop-blur-md` | `BackdropFilter` + `ImageFilter.blur` | 层数少、区域可控；低端机可改为纯色半透明 + 边框，**功能不变**。 |
| 阴影 | `box-shadow` 多段、扩散 | `BoxShadow` 近似 | 允许色相/扩散与 CSS 有偏差。 |
| 边框半透明 | `border-white/60` | `Color.fromRGBO` / `withValues` | 与设备 gamma 差异可接受。 |
| 圆角 | `rem` 连续缩放 | 逻辑像素取整 | ±1px 级差异可接受。 |
| 字体 | `font-sans` 等 | `GoogleFonts.notoSansSc` 等已存在 | 字重/行高与 web 不必完全一致。 |
| 动效与滚动 | CSS `scroll-smooth`、关键帧 | Flutter 动画 API | 不强制复刻官网动效曲线。 |

**结论**：若某效果在 Flutter 上实现成本过高或影响性能，**允许与 web 不一致**，但须保持可读性、可点按区域与业务逻辑不变；须在实现或 CR 中简短注明「降级原因」（可选记入 PR 说明）。

## 10. 参考

- 仓库内：`web/app/globals.css`（`:root` light、`--radius`）、`web/components/glass-card.tsx`。
- Flutter：`flutter/lib/core/theme/app_theme.dart`、`flutter/lib/widgets/glass_card.dart`（若路径不同以实际为准）。
- 设计原则：Claude 技能 **frontend-design**（高完成度前端界面：清晰层级、一致间距、克制装饰）— 作审美约束，非代码依赖。
- 项目约束：`AGENTS.md`、`flutter/.cursor/rules/dart-style.mdc`（const、Theme、禁止硬编码色值等）。
