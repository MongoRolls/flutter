# 弹窗 / 底栏迁移清单（`flutter_dialog_unification`）

> 生成方式：对 `flutter/lib` 检索 `showDialog`、`AlertDialog`、`showModalBottomSheet`；封装实现位于 `lib/common/widgets/app_confirm_dialog.dart`、`app_dialog.dart`、`app_info_dialog.dart`、`app_modal_sheet.dart`。

## 已迁移（统一封装或 `AppDialogScaffold`）

| 区域 | 说明 |
|------|------|
| `features/chat/screens/chat_screen.dart` | 清空对话 → `showAppConfirmDialog`（destructive） |
| `features/settings/screens/health_archive_screen.dart` | 删除记忆 → `showAppConfirmDialog` |
| `features/debug/screens/debug_screen.dart` | 测试前确认 → `showAppConfirmDialog` |
| `features/plan/widgets/action_row.dart` | 设为今日目标 / 设置提醒 → `showAppConfirmDialog` |
| `features/plan/widgets/ai_plan_result_section.dart` | 重新生成计划 → `showAppConfirmDialog`（橙色主按钮） |
| `features/plan/widgets/slot_timeline.dart` | 时段底栏 → `showAppModalSheet` |
| `features/home/screens/home_screen.dart` | 快速饮水 / 管理杯子底栏 → `showAppModalSheet`；添加/编辑杯子 → `AppDialogScaffold` |
| `features/community/screens/add_contact_screen.dart` | 我的短码底栏 → `showAppModalSheet` |

## 保留框架 API 的封装层（无需再改业务）

- `showAppConfirmDialog` / `showAppInfoDialog` 内部仍使用 `showDialog`。
- `showAppModalSheet` 内部仍使用 `showModalBottomSheet`。

## 后续新增 UI 约定

- 短文案确认 / 删除 → `showAppConfirmDialog`（destructive 用 `isDestructive: true`）。
- 单按钮告知 → `showAppInfoDialog`。
- 长内容 / 列表 / 二维码等 → `showAppModalSheet`。
- 自定义表单仍可用 `AppDialogScaffold` + `showDialog`（如首页编辑杯子）。
