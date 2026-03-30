## 1. Flutter — Token 文档与对照

- [x] 1.1 阅读仓库内只读参考（营销站 light 的 CSS 变量与 Glass 组件源码路径见 `proposal.md` / 结构化需求），整理 **web light ↔ Flutter** 对照表：背景、主色/语义色、`--radius` 阶梯、`--border`、阴影与 GlassCard light 意图。
- [x] 1.2 将对照表写入仓库约定路径（优先 `flutter/doc/design-tokens.md` 或 `.cursor/project/` 下单一 Markdown，并在 `openspec/specs/SPEC.md` 或本变更归档时更新索引链接，按团队惯例选其一）。

## 2. Flutter — 全局主题（仅 light）

- [x] 2.1 在 `flutter/lib/core/theme/` 收紧 `AppColors` / `AppTheme`：`Scaffold` 背景、卡片表面、`ColorScheme`、主要 `TextTheme` 层级，与对照表一致；不引入深色 `ThemeData`。
- [x] 2.2 全局搜索并替换仍与对照表冲突的大面积硬编码色值（业务逻辑不变）。

## 3. Flutter — 通用容器与间距

- [x] 3.1 更新 `flutter/lib/common/widgets/glass_card.dart`（及同类封装）：统一圆角（约 16px 意图）、阴影、`BoxShadow` 近似、边框透明度；为性能保留可接受的模糊降级分支。
- [x] 3.2 在主导航相关屏将重复的 `BoxDecoration` 收敛为上述组件或 theme 扩展；列表/区块垂直间距使用有限集合（8/12/16/24）。

## 4. Flutter — 核心屏样式抽检

- [x] 4.1 刷新 Home、Settings、Community（或当前底部三 Tab）的样式层，确保使用新主题与容器；不大改布局与区块顺序。
- [x] 4.2 在较大系统字体下抽查主要布局无恶化溢出（与改前对比）。

## 5. 验证与验收

- [x] 5.1 在 `flutter/` 下运行 `flutter analyze` 与 `flutter test`，修复由本变更引入的问题。
- [x] 5.2 产品于真机或模拟器手动验收约定屏幕，确认可发布或记录可接受偏差清单。
