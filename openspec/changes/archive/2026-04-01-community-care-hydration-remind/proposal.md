## Why

关怀好友流程已支持短码添加与联系人 CRUD，但好友饮水摘要仍依赖客户端占位字段，「提醒喝水」仅为占位弹窗，且服务端未强校验联系人数量上限。需要打通 **摘要拉取 → 模板发送 → 接收侧提示/通知** 的闭环，并与现有 `community.md` / `notifications.md` 规格对齐，避免产品与实现长期分叉。

## What Changes

- **后端**：在 `upsertContact` 中校验每位用户关怀联系人 ≤ 20，超出返回 `ValidationError`（4xx）。
- **后端**：实现 `GET /api/care/peers/hydration`（按日期与时区偏移返回已建立关怀关系的好友当日 `todayMl` / `dailyGoalMl` / `visible`），权限遵循「仅 owner 可见已添加的对方摘要」的非对称模型。
- **后端**：实现 `POST /api/care/remind`（向指定关怀联系人发送提醒；与推送/站内消息策略一致，具体通道在设计与实现中落地）。
- **可选（与文档一致时）**：用户资料增加 `shareHydrationWithCareContacts`（默认 true）；关闭时摘要对 peers 返回 `visible: false`。
- **Flutter**：用接口数据替换 `CareContact` 上 `mockTodayMl` / `mockDailyGoalMl` 的展示路径；重构 `peer_remind_template_sheet` 为 3～4 个固定模板 + 发送；成功后 Toast 与「关怀行为」记录（与现有本地时间线/后端日志策略一致）。
- **Flutter**：`NotificationService` 为好友提醒使用与普通喝水提醒 **分离的 channel**（Android channel id、iOS category 等）；标题/正文与模板一致。
- **Flutter（产品待定）**：社区 Tab 未读关怀/提醒的 badge 或入站提示（触发条件在 spec delta 中写清占位或可配置项）。

## Capabilities

### New Capabilities

- （无独立新领域规格；行为增量通过下列既有能力 delta 交付。）

### Modified Capabilities

- `community`：补充关怀联系人数量服务端校验；好友饮水摘要 API；向好友发送提醒 API；可选隐私字段与 `visible` 语义；与 `HeartProvider` / `CareContact` 数据流对齐。
- `notifications`：关怀通知与普通日程提醒 **渠道分离**；接收侧本地通知文案与模板摘要；更新 REQ-NOTIF-04 与 ID/渠道约定（若与现有 9000+ 关怀通知范围有扩展则写入 delta）。

## Impact

- **后端**：`backend/src/services/care.service.ts`、`backend/src/routes/care.routes.ts`；可能涉及 Prisma 模型与用户资料字段； drink 日志聚合查询（按用户、日、时区）。
- **Flutter**：`flutter/lib/features/community/`（`heart_provider.dart`、`care_contact.dart`、`peer_remind_template_sheet.dart`、`care_contact_card.dart`、`community_screen.dart` 等）、`flutter/lib/core/services/notification_service.dart` 及平台通知配置（Android manifest / iOS / macOS 如适用）。
- **依赖**：客户端与 API 契约同步；若使用远端推送则需与现有后端推送/设备 token 策略一致（见项目 todo/推送相关文档）。
