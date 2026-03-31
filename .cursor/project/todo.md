# KeLeME 待办清单

## 社区 · 心连心（社区关怀增强）

### 背景与参考

- **心连心**：在现有社区能力（好友码、关怀联系人、挑战广场等）上扩展的关怀体验。UI 参考仓库根目录 [`心连心通知界面.html`](../../心连心通知界面.html)（演示稿，非最终实现；部分能力需产品拍板）。
- **规格真源**：[`openspec/specs/community.md`](../../openspec/specs/community.md)；通知行为见 [`openspec/specs/notifications.md`](../../openspec/specs/notifications.md)。**大改请走 `openspec/changes/...`**，本文件只作专题 backlog。

### 已定范围

- **发送关怀**：以 **Modal** 呈现（如 `showModalBottomSheet` / `showDialog`），不按 HTML 做成社区页内嵌一整块发送区。
- **关怀足迹**（双向时间线、对方回复等）：**本期不做**，本文档不列交付项。

### 目标体验（来自原型）

- **通知样式**：原型含三类横幅（心连心含快捷操作、AI 转达、恋人消息等）；真实「接收方横幅 + 快捷操作」依赖推送能力。
- **我的关怀圈**：联系人列表、状态与进度环、提醒入口、添加关怀的人。
- **AI 温馨提示**：基于场景的建议（例：某时段更适合提醒某人）——**可选**，非必须一期。
- **发送关怀**：话术模板、自定义文案、多收件人、发送主按钮；在 **Modal** 内完成。
- **信息架构**：原型底栏为「喝水 / 心连心 / 广场 / 我的」；现 App 为单一「社区」Tab 聚合——**是否拆分 Tab** 为产品决策项。
- **不包含**：关怀足迹区块。

### 实现入口（代码）

- [`community_screen.dart`](../../flutter/lib/features/community/screens/community_screen.dart) — 社区 Tab 聚合
- [`heart_provider.dart`](../../flutter/lib/features/community/providers/heart_provider.dart) — 关怀联系人
- [`peer_remind_template_sheet.dart`](../../flutter/lib/features/community/widgets/peer_remind_template_sheet.dart) — 发送关怀模板（与 Modal 对齐）
- [`notification_service.dart`](../../flutter/lib/core/services/notification_service.dart) — 本地通知（含心连心类渠道说明）

### 与现状差距及依赖（按类型标注）

| 类型 | 内容 | 阻塞 / 依赖 |
|------|------|-------------|
| **产品决策** | 社区 Tab 是否拆成「心连心」独立入口 | 影响导航与 `MainShell`；未定时勿当作纯开发任务 |
| **后端推送** | 接收方真实通知、通知上操作按钮 | 规格「远端推送规划中」；**推送方案未定则不做按钮真响应** |
| **隐私与同步** | 对方今日饮水进度可见 | 需对方授权与数据协议；`CareContact` 上 `mockTodayMl` 等仅为占位 |
| **客户端 UI** | 模板 / 多选收件人 / 润色 / 语音等与 `peer_remind_template_sheet` 对齐 | **交互统一为 Modal**（底栏或居中弹窗按平台习惯） |
| **动效与视觉** | HTML 渐变与动效 | 对齐 `AppTheme`，不必一期像素级复刻 |

补充说明（非表格）：

- **通知**：当前规格下关怀通知多为**发送方本机**即时反馈；原型中的**接收方系统通知样式**需推送通道与前后台策略（见 `notifications.md`）。

### 状态与下一步

- **状态**：边界已部分收敛（发送用 Modal、不做足迹）；其余待与产品 / AI 对齐。
- **下一步**：范围确定后新增或更新 **OpenSpec change**，并 delta `community.md` / `notifications.md`，避免本文件无限膨胀。

### 不建议默认承诺

- 不把 HTML 动效、对方实时进度、双向回复列为近期里程碑，除非后端与隐私范围已确认（参见 [`backend/README.md`](../../backend/README.md) 中社区相关阶段）。
