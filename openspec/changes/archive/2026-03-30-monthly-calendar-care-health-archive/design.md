## Context

- 首页打卡数据来自 `UserProvider.monthlyHits` 与当日 `dailyGoalMl`，现状 `_buildStreakCalendar` 用 `Wrap` 顺序排布 1…N，且 `d > today` 时使用 `AppColors.divider` 作为文字色导致对比度过低。
- 社区添加联系人：`add_contact_screen.dart` 含扫码 `IconButton` 与 `ScanFriendCodeScreen`；好友码展示已有「我的短码」sheet，后端已有 `GET/POST` 好友码与轮换能力（见 `openspec/specs/community.md` REQ-CARE-01）。
- 健康档案：`MemoryService` 已有 Hive `deleteFact`；后端 `DELETE /api/memory/:id` 已存在；Flutter 侧可能尚未封装 `deleteMemory` HTTP 调用。

## Goals / Non-Goals

**Goals:**

- 月历与系统 locale 一致采用 **周日为一列起始**（`weekday` 以 `DateTime` 的 `weekday` 换算：周一=1…周日=7 → 周日列索引 0）。
- 未来日期：保持「未发生」状态样式，但数字使用 `textHint` 或等效可读色，**禁止**与分割线色同档。
- 添加关怀：仅文本输入 + 保存；「我的短码」支持用户主动刷新看见新码。
- 删除档案：确认对话框 → 请求后端删除 → 成功后再删本地；失败提示并保持本地数据（或按产品决定：见开放问题）。

**Non-Goals:**

- 重做 `monthlyHits` 持久化或后端饮水同步。
- 软删除、回收站。
- 批量导出、全量清空（另有入口则不复述）。

## Decisions

| 决策 | 选项 | 理由 |
|------|------|------|
| 周历布局 | `Table` / `Column`+`Row` 固定 7 列，或 `GridView` 固定 `crossAxisCount: 7` | 避免 `Wrap` 在窄屏下断行错位；需统一行高与单元格宽度（可略小于现状 34 以适配 320pt）。 |
| 首列星期 | 周日 | 用户已确认；与 `DateTime.weekday` 需显式映射。 |
| 周表头 | 单行「日一二三四五六」或缩写 | 与 `AppTheme` 小字样式一致即可；若垂直空间不足可省略表头仅保留网格。 |
| 本月达标天数 | 统计 `<= today` 且 `>= goalMl` 的日键 | 与「今日达标」一致，修复仅统计 `< today` 的偏差。 |
| 移除扫码 | 移除按钮与 `_openScan`；删除 `scan_friend_code_screen` 的 import；若路由无其他引用可考虑从 `pubspec` 移除扫描依赖 | 产品要求仅口令。 |
| 好友码刷新 | 在 `_MyFriendCodeSheet` 增加「刷新」/「换一个新码」→ 调用 `POST /api/care/friend-code/rotate`（或现有 `BackendApiService` 等价方法） | 用户要求；协议已存在。 |
| 删除同步 | `BackendApiService.deleteMemoryFact(String id)` 使用 `DELETE /api/memory/:id`；成功 204 后 `MemoryService.deleteFact` | 用户要求云端同步删除；后端已具备。 |
| 删除失败 | 默认：提示错误，**不**删本地，避免与云端不一致 | 若需「离线仅本地删除」可后续加开关。 |

## Risks / Trade-offs

- **窄屏**：7 列 + 间距可能导致单元格过小 → 减小 `spacing` 或字体 10→9，并在 320 宽度下人工看一眼。
- **删除失败**：用户看到记录仍在，需文案说明「已同步失败，请重试」。
- **移除扫码包**：若其他页面仍引用扫描，则保留依赖仅删本页 UI。

## Migration Plan

- 客户端发版即可；无需数据迁移。
- 若减少 `pubspec` 依赖，在确认全仓库无 `mobile_scanner` 引用后执行。

## Open Questions

1. 删除请求失败时，是否允许「仅删除本地」作为二次操作（当前设计为不允许，需产品拍板）。
2. 好友码轮换是否需在刷新前二次确认（防止误点导致旧码失效）。
