## 1. Flutter — 首页本月打卡

- [x] 1.1 在 `home_screen.dart` 将 `_buildStreakCalendar` 改为固定 7 列周历（周日起），计算月初 `weekday` 偏移并生成占位格；可选增加周表头行。
- [x] 1.2 调整未来日期与「未达标」的样式：未来日期使用可读文字色（如 `textHint`），与 `divider` 区分。
- [x] 1.3 修正「本月 X 天达标」统计：包含今日达标，排除未来日期；自测与图例一致。
- [x] 1.4 窄屏（约 320pt）下检查布局与字号，必要时微调间距或单元格尺寸。

## 2. Flutter — 社区添加关怀联系人

- [x] 2.1 在 `add_contact_screen.dart` 移除扫码入口、`_openScan` 及对 `ScanFriendCodeScreen` 的引用；更新 hint 文案。
- [x] 2.2 在「我的短码」sheet（`_MyFriendCodeSheet`）增加刷新/轮换按钮，调用 `BackendApiService.rotateFriendCode()` 并刷新展示。
- [x] 2.3 全仓库检索 `ScanFriendCodeScreen` / `mobile_scanner`；若无引用则可选从 `pubspec.yaml` 移除扫描依赖并 `flutter pub get`。

## 3. Flutter — AI 健康档案删除

- [x] 3.1 在 `backend_api_service.dart` 增加 `deleteMemoryFact(String id)`（`DELETE /api/memory/:id`），处理 204 与错误。
- [x] 3.2 在 `health_archive_screen.dart` 为条目增加删除入口（滑动或菜单）；使用 `AppConfirmDialog` 或项目现有确认样式二次确认。
- [x] 3.3 实现删除流程：先请求后端，成功后再 `MemoryService.deleteFact` 并 `setState`；失败时 `AppToast` 提示且保留本地。
- [x] 3.4 删除后若列表为空则显示既有空状态；`flutter analyze` 通过。

## 4. Backend（按需）

- [x] 4.1 核对 `DELETE /api/memory/:id` 行为与鉴权、404 与当前 Prisma 模型一致；若前端需要更明确错误体再小改（默认不改）。
