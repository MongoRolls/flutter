## Context

- 产品规则见 `.cursor/project/社区关怀好友与提醒.md`：好友短码已落地；客户端对关怀联系人数量有 20 人校验，但服务端 `upsertContact` 尚未强校验；好友饮水展示仍用 `mockTodayMl` / `mockDailyGoalMl`；`peer_remind_template_sheet` 为占位；`GET /api/care/peers/hydration` 与 `POST /api/care/remind` 未实现。
- 饮水日志已通过 `POST /api/drink-logs/bulk-sync` 落库，摘要接口需按 owner 视角聚合「已添加的联系人」在指定本地日的摄入量与目标。

## Goals / Non-Goals

**Goals:**

- 服务端与客户端一致 enforce 每位用户最多 20 位关怀联系人（新建 upsert 时超限明确 4xx）。
- 提供按日、按时区解释的 peers 饮水摘要 API，供 Flutter 替换 mock 字段并驱动 `progress` / `status`。
- 提供向好友发起提醒的后端能力，并与 Flutter 模板选择、成功反馈衔接；通知渠道与普通日程提醒分离。
- 规格 delta 可归档进 `openspec/specs/community.md` 与 `notifications.md`。

**Non-Goals:**

- Next.js 官网（`web/`）任何改动。
- 挑战广场（REQ-CARE-05）业务扩展。
- 在本变更中强制实现完整远端推送基础设施（若当前仅有本地/占位，则在任务中分阶段：接口先行、推送适配后续）。

## Decisions

1. **联系人上限校验位置**：在 `care.service.ts` 的 `upsertContact` 内对 `ownerId` 做 `count`（仅统计有效联系人行），在插入新关系前若已达 20 且本次为新增则抛 `ValidationError`；与客户端 `AddContactScreen` 提示文案对齐。
2. **Peers hydration 语义**：
   - 查询维度：当前登录用户为 owner，返回其 `CareContact` 列表中每个 `contactId` 在 `date`（与 `tzOffset` 共同确定的「用户日历日」）下的 `todayMl`、`dailyGoalMl`。
   - `dailyGoalMl` 来源：以用户资料/同步目标为准（与现有 drink 目标字段一致）；若某联系人无有效目标，在响应中仍可返回数字或约定默认值（与后端现有 User 模型一致）。
   - **非对称可见**：仅 owner 添加的对方出现在列表中；不要求互相关注。
3. **`visible` 字段**：当实现 `UserProfile.shareHydrationWithCareContacts`（或后端等价字段）且为 `false` 时，该用户作为「被查看方」在他人 peers 结果中返回 `visible: false`，且不暴露具体毫升数（或统一返回 null，由 spec 锁定一种）；默认 `true`。
4. **Remind API**：`POST /api/care/remind`，body 含 `contactId`（或 `careContactId`）与 `templateId`（1–4 与产品模板表一致）。服务端校验 owner–contact 关系存在；后续动作：写入提醒事件、触发推送（FCM/APNs 等）或站内 inbox——**以实现时已有基础设施为准**；若尚无推送，则先持久化 + 200，客户端仍走本地 Toast，并在规格中标注「接收侧推送为阶段二」。
5. **Flutter 模板 UI**：`peer_remind_template_sheet.dart` 使用固定 3～4 条模板（文案与 `.cursor/project/社区关怀好友与提醒.md` Step 4 一致），选中后启用发送；调用 `BackendApiService` 新方法；成功：`SnackBar`/Toast + 可选本地「关怀记录」写入（与现有 `CareRecord` 时间线一致）。
6. **通知渠道分离**：在 `NotificationService` 注册独立 Android `NotificationChannel`（如 `keleme_care_peer`）与 iOS `DarwinNotificationDetails` 的 category（若适用）；与普通 `scheduleReminders` 使用的 channel 不得混用。接收好友提醒时使用该 channel 展示标题（含发送方昵称或「好友提醒」）与模板摘要正文。

**Alternatives considered**

- **对称好友关系**：需双向 `CareContact` 或 Friend 表，超出当前产品；保留非对称。
- **仅客户端校验 20 人**：拒绝——与文档要求服务端强校验不符。

## Risks / Trade-offs

- **[Risk] 时区与日界**：客户端传 `date` + `tzOffset` 与服务器 UTC 存储不一致导致「算错天」。→ **Mitigation**：约定 `date` 为 `YYYY-MM-DD` 表示用户本地日历日，`tzOffset` 为分钟偏移；服务端用统一规则将 drink 日志映射到该本地日（与 bulk-sync 存储策略一致）。
- **[Risk] 推送未就绪时 remind 接口「空转」**。→ **Mitigation**：接口仍落库 + 返回成功，规格写明阶段性；避免客户端误以为对方手机已收到。
- **[Risk] 通知渠道误配导致用户关闭「所有提醒」**。→ **Mitigation**：独立 channel，设置页可分别说明「日程提醒」与「好友提醒」。

## Migration Plan

1. 部署后端：先上线 count 校验与 hydration/remind 路由（特性开关可选）。
2. 发布 Flutter：依赖新 API；旧客户端仍用 mock，直到升级。
3. 若新增 User 字段 `shareHydrationWithCareContacts`：Prisma migrate → 默认 `true` → 无需用户强制操作。

**Rollback**：后端回滚上一版本；Flutter 若已移除 mock 回退需保留「接口失败时显示占位或 `--`」的降级（可在任务中列为验收项）。

## Open Questions

- 社区 Tab **未读 badge** 的精确触发（仅新 remind？未读条数？）需产品拍板；本变更可在 spec 中 **ADDED** 一条占位需求或列入 Non-Goals 直至明确。
- 远端推送证书/FCM 与现有用户 device token 表是否已存在；若不存在，`/care/remind` 先只做持久化 + 轮询/拉取模型。
