## 1. Flutter — 标准模态封装与主题绑定

- [x] 1.1 在 `flutter/lib/common/widgets/` 实现 `AppConfirmDialog`（居中、`bgCard`、双按钮、`Future<bool?>`、破坏性主按钮 destructive 色）。
- [x] 1.2 实现 `AppInfoDialog`（与确认框同几何、单主按钮、`ElevatedButton` 风格与 `AppColors.blue` 一致）。
- [x] 1.3 实现 `AppModalSheet`（`showModalBottomSheet`、顶角圆角、拖动条、可滚动内容、`isScrollControlled`、安全区）。
- [x] 1.4 在 `flutter/lib/core/theme/app_theme.dart` 配置 `DialogTheme` / 必要时 `BottomSheetThemeData`，使默认形状与颜色与封装一致。
- [x] 1.5 在合适位置导出封装（如 `common/widgets` barrel 或按需 import），便于业务引用。

## 2. Flutter — 文档与设计 token

- [x] 2.1 更新 `flutter/doc/design-tokens.md`：增加模态层 token 表（圆角、宽度、destructive、底栏顶角、把手色、与 `GlassCard` 区分说明）。
- [x] 2.2 与 `openspec/changes/flutter-dialog-unification/specs/design-tokens/spec.md` 对齐，确保归档后主规格可合并无冲突。

## 3. Flutter — 存量迁移（P1）

- [x] 3.1 检索 `flutter/lib` 中 `showDialog` / `AlertDialog` / `SimpleDialog` / `showModalBottomSheet`，建立待迁移清单。
- [x] 3.2 迁移高频路径：`home_screen`、聊天相关、`health_archive_screen`、`plan/` 下屏幕、`add_contact_screen`、`debug_screen` 等至统一封装或主题。
- [x] 3.3 处理剩余调用或标注过渡期注释，确保无明显裸样式分叉。

## 4. Flutter — 测试与静态分析

- [x] 4.1 补充最小 widget 测试（例如确认框按钮回调、destructive 主色、info 单按钮）。
- [x] 4.2 运行 `flutter analyze` 与 `flutter test`，全部通过后再合并。
