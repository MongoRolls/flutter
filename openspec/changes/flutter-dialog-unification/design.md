## Context

- 当前 `flutter/lib` 中多处直接使用 `AlertDialog`、`SimpleDialog`、`showModalBottomSheet`，样式与 `AppTheme`、`AppColors`、`AppRadius`、`AppShadows` 未系统对齐；与页面内 `GlassCard` 装饰策略混用时，模态层视觉不一致。
- 产品已确认：弹窗内容区为**纯色卡片**（非毛玻璃）；允许 **2～3 种**标准封装并存；破坏性操作主按钮用 **destructive** 色；遮罩与点外部关闭等 **默认沿用 Material** 行为。

## Goals / Non-Goals

**Goals:**

- 提供 **`AppConfirmDialog` / `AppInfoDialog` / `AppModalSheet`**（名称以实现为准），覆盖确认、告知、底部长内容三类场景，并与 `AppTheme.lightTheme` 绑定。
- 通过 `DialogTheme`/组件封装减少裸 `AlertDialog` 分叉；迁移高频路径（首页、聊天、健康档案、计划、联系人、调试等）至统一入口。
- 更新 `openspec/specs/design-tokens` 与 `flutter/doc/design-tokens.md`，使模态相关 token 与代码一致。

**Non-Goals:**

- 不修改 `web/`；不引入 Provider/Riverpod/go_router；不以 `CupertinoAlertDialog` 为主路径（除非后续单独约定）；不重写非模态页面信息架构。

## Decisions

| 决策 | 选择 | 理由 / 备选 |
|------|------|----------------|
| 组件形态 | 三种封装 + 可选 `DialogTheme` 默认值 | 与需求 §8 一致；单一 `AlertDialog` 子类难以覆盖底栏交互。 |
| 确认框尺寸 | `min(400, 屏宽-48)` 水平居中 | 与结构化需求一致；过大屏可读性上限。 |
| 圆角 | 居中对话框在 `AppRadius.xl` 与 `x2l` 中**实现时二选一写死** | 避免运行时漂移；与 token 文档同步最终值。 |
| 破坏性主按钮 | `AppColors.red` / `redDeep` 背景 + 白字 | 已确认决策；与「取消」次要按钮区分。 |
| 底栏 | `showModalBottomSheet` + `isScrollControlled: true`（长内容）；顶角 `AppRadius.x2l`～`x3l`；拖动条 + 可选 `SafeArea` | 与需求一致；`DraggableScrollableSheet` 仅在需要时纳入封装。 |
| 迁移策略 | 先封装与主题，再按屏幕分批替换 | 降低回归面；P1 可接受过渡期清单。 |

## Risks / Trade-offs

- **[Risk] 迁移面广导致回归** → 分模块合并；每批跑 `flutter analyze` / `flutter test`；保留检索清单追踪剩余裸 `AlertDialog`。
- **[Risk] 与 `GlassCard` 视觉混淆** → 文档与代码注释明确「页面卡片可毛玻璃，模态内容区纯色」。
- **[Trade-off] 仅 light 主题** → 与当前工程一致；若未来深色模式，需在 `ThemeData` 扩展暗色模态 token。

## Migration Plan

1. 在 `common/widgets` 落地三个封装并导出；在 `app_theme.dart` 配置 `DialogTheme`（及 `BottomSheetThemeData` 若需要）以统一默认形状/颜色。
2. 按 feature 替换 `showDialog` / `showModalBottomSheet` 调用（优先 P0 路径与高频确认流）。
3. 同步 design-tokens 与 `flutter/doc/design-tokens.md`。
4. 可选：补充 widget 测试后收尾。

**Rollback:** 回退提交即可；无数据迁移。

## Open Questions

- 实现中若「长内容 vs 半屏底栏」边界不清，在 `modal-dialogs` spec 或 `design-tokens` 文档补一节选用表（需求已预留）。
