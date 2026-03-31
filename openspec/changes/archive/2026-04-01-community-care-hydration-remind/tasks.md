## 1. Backend — 联系人上限与路由骨架

- [x] 1.1 在 `backend/src/services/care.service.ts` 的 `upsertContact` 中增加 owner 维度 `CareContact` 计数；新建联系人且已达 20 时抛 `ValidationError`（4xx）
- [x] 1.2 为 `GET /api/care/peers/hydration`、`POST /api/care/remind` 在 `backend/src/routes/care.routes.ts` 注册路由并接入 auth；占位 handler 可先返回 501 或最小实现（按开发顺序）
- [x] 1.3 实现 `peers/hydration`：按 `date` + `tzOffset` 聚合 drink 日志与目标，返回 `[{ userId, todayMl, dailyGoalMl, visible }]`
- [x] 1.4 （可选）若落地 `shareHydrationWithCareContacts`：扩展 Prisma User/UserProfile 字段、默认值 `true`，并在 hydration 查询中设置 `visible`

## 2. Backend — 提醒与持久化

- [x] 2.1 实现 `POST /api/care/remind`：校验 owner–contact 关系，解析 `templateId`，写入提醒事件或等价表
- [x] 2.2 若项目已有推送服务：在 remind 成功路径触发推送；否则在代码或 README 中标注阶段二，并保证接口契约稳定
- [x] 2.3 为上述接口补充单元/集成测试或最小手工验收说明（`backend/`）

## 3. Flutter — API 与数据模型

- [x] 3.1 在 `BackendApiService`（或现有 care API 封装）中增加 `getPeersHydration`、`sendCareRemind`（命名与项目一致）
- [x] 3.2 更新 `CareContact` / `HeartProvider`：拉取 hydration 后填充真实 `todayMl` / `dailyGoalMl`（移除或降级 mock 路径）；失败时保留降级展示
- [x] 3.3 若后端支持隐私字段：在 `UserProfile` 与设置页增加 `shareHydrationWithCareContacts` 同步（与 `UserProvider` 持久化一致）

## 4. Flutter — 模板 UI 与发送

- [x] 4.1 重构 `flutter/lib/features/community/widgets/peer_remind_template_sheet.dart`：3～4 个固定模板 chip、选中后启用发送、调用 `POST /api/care/remind`
- [x] 4.2 发送成功：Toast/SnackBar；可选写入本地关怀时间线（与 `CareRecord` / `HeartProvider` 现有行为对齐）
- [x] 4.3 更新 `care_contact_card.dart` 等入口，确保错误态与 loading 可访问性合理

## 5. Flutter — 通知渠道

- [x] 5.1 在 `flutter/lib/core/services/notification_service.dart` 注册独立 Android `NotificationChannel`（及 iOS/macOS 等价配置）用于好友/心连心提醒
- [x] 5.2 接收端展示时使用该 channel 与模板摘要正文；与 `scheduleReminders` 所用 channel 分离
- [x] 5.3 核对 Android 清单 / iOS 如需 category 等配置（`flutter/` 平台目录）

## 6. 社区与验收

- [x] 6.1 `community_screen.dart`：下拉刷新时拉取 hydration（必要时并行 contacts）；未读 badge 若产品未定则留 TODO 或占位开关
- [x] 6.2 运行 `flutter analyze` 与相关测试；后端 `npm test` 或项目约定脚本
- [x] 6.3 实现完成后 `/opsx:archive` 归档并合并主规格（`openspec/specs/community.md`、`notifications.md`）
